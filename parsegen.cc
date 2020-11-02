#define FMT_HEADER_ONLY

#include <cstring>
#include <cstdio>

#include <iostream>
#include <fstream>
#include <string>
#include <set>
#include <vector>

#include "fmt/printf.h"

#include <clang-c/Index.h>
#include <clang-c/CXString.h>

using namespace std;

ostream& operator<<(ostream& stream, const CXString& str)
{
    stream << clang_getCString(str);
    return stream;
}

template <typename T1, typename T2>
bool contains(T1 && s, T2 && k) {
    return s.find(std::forward<T2>(k)) != s.end();
};


std::set<string> openblas64_exports;
std::set<string> ilp64_exports;
FILE * output_file;

CXChildVisitResult
parse(CXCursor c, CXCursor parent, void * client_data)
{
    std::set<string> * p_defined = static_cast<std::set<string>*>(client_data);

    auto kind = clang_getCursorKind(c);
    if (kind != CXCursor_FunctionDecl) { return CXChildVisit_Continue; }

    string name = clang_getCString(clang_getCursorSpelling(c));
    string stem = "";

    if (name.size() == 0) {
        return CXChildVisit_Continue;
    } else if (name.at(name.size() - 1) == '_') {
        stem = name.substr(0, name.size() - 1);
    } else {
        stem = name;
    }

    string caller = ""; // from openblas64
    string callee = ""; // from ilp64

    if (contains(ilp64_exports, stem)) {
        callee = stem;
    } else if (contains(ilp64_exports, stem + "_")) {
        callee = stem + "_";
    } else {
        return CXChildVisit_Continue;
    }

    std::vector<std::string> callers;
    if (contains(openblas64_exports, stem + "64_")) {
        callers.push_back(stem + "64_");
    } 
    if (contains(openblas64_exports, stem + "_64_")) {
        callers.push_back(stem + "_64_");
    }

    for(auto const & caller: callers) {
        if (contains(*p_defined, caller)) {
            continue;
        }
        p_defined->insert(caller);

        auto type = clang_getCursorType(c);
        auto nargs = clang_Cursor_getNumArguments(c);

        fmt::print(output_file, "API_EXPORT\n");
        fmt::print(output_file, "{}\n", clang_getTypeSpelling(clang_getResultType(type)));

        fmt::print(output_file, "{}(", caller);
        for (decltype(nargs) i = 0 ; i < nargs ; ++i) {
            auto arg = clang_Cursor_getArgument(c, i);
            fmt::print(output_file, "{}{} {}", 
                i == 0 ? "" : ", ",
                clang_getTypeSpelling(clang_getArgType(type, i)),
                clang_getCursorSpelling(arg)
            );
        }
        fmt::print(output_file, ")\n");

        fmt::print(output_file, "{{\n");
        if (strcmp(clang_getCString(clang_getTypeSpelling(clang_getResultType(type))), "void") == 0) {
            fmt::print(output_file, "  {}(", callee);
        } else {
            fmt::print(output_file, "  return {}(", callee);
        }
        for (decltype(nargs) i = 0 ; i < nargs ; ++i) {
            auto arg = clang_Cursor_getArgument(c, i);
            fmt::print(output_file, "{}{}", (i == 0 ? "" : ", "), clang_getCursorSpelling(arg));
        }
        fmt::print(output_file, ");\n");
        fmt::print(output_file, "}}\n\n");
    }

    return CXChildVisit_Continue;
}


int main(int argc, char** argv)
{
    if (argc < 5) {
        fmt::print("usage: {} <output_file> <list_intel_ilp64> <list_openblas64> <header> [header] ...\n", argv[0]);
        std::cout << std::endl;
        exit(1);
    }
    {
        std::ifstream in(argv[2]);
        if (in.fail()) {
            fmt::print("failed to load file {}\n", argv[2]);
            exit(1);
        }
        string buf;
        while(!in.eof()) {
            in >> buf;
            ilp64_exports.insert(buf);
        }
    }
    {
        std::ifstream in(argv[3]);
        if (in.fail()) {
            fmt::print("failed to load file {}\n", argv[1]);
            exit(1);
        }
        string buf;
        while(!in.eof()) {
            in >> buf;
            openblas64_exports.insert(buf);
        }
    }

    output_file = fopen(argv[1], "w");

    std::set<string> defined;
    fmt::print(output_file, "#include \"mklopenblas64.h\"\n\n");
    const char * const command_line_args[1] = { "-DMKL_ILP64" };
    auto process = [&](const char* filename) {
        CXIndex index = clang_createIndex(0, 0);
        CXTranslationUnit unit = clang_parseTranslationUnit(
                index,
                filename, command_line_args, 1,
                nullptr, 0,
                CXTranslationUnit_None
                );
        if (unit == nullptr) {
            cerr << "Unable to parse translation unit. Quitting." << endl;
            exit(-1);
        }
        CXCursor cursor = clang_getTranslationUnitCursor(unit);
        clang_visitChildren(cursor, parse, &defined);
        clang_disposeTranslationUnit(unit);
        clang_disposeIndex(index);
    };
    for (int i = 4 ; i < argc ; ++i) {
        process(argv[i]);
    }
    fclose(output_file);
}
