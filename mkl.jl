using Clang
using Clang.LibClang.Clang_jll

const LIBCLANG_INCLUDE = joinpath(dirname(Clang_jll.libclang_path), "..", "include", "clang-c") |> normpath
const LIBCLANG_HEADERS = [joinpath(LIBCLANG_INCLUDE, header) for header in readdir(LIBCLANG_INCLUDE) if endswith(header, ".h")]


# Configuration
mkl_root = "/usr/lib/x86_64-linux-gnu"
mkl_libraries = [
    "/usr/lib/x86_64-linux-gnu/libmkl_core.a",
    "/usr/lib/x86_64-linux-gnu/libmkl_gf_ilp64.a",
    "/usr/lib/x86_64-linux-gnu/libmkl_gnu_thread.a",
    "/usr/lib/x86_64-linux-gnu/liblapacke64.a",
]
mkl_headers = [
    "/usr/include/mkl/mkl_blas.h",
    "/usr/include/mkl/mkl_cblas.h",
    "/usr/include/mkl/mkl_lapack.h",
    "/usr/include/mkl/mkl_lapacke.h",
    "/usr/include/mkl/mkl_trans.h",

    # "/usr/include/lapacke_utils.h",
    # "/usr/include/lapacke.h",
    # "/usr/include/x86_64-linux-gnu/openblas64-openmp/cblas.h",
    # "/usr/include/x86_64-linux-gnu/openblas64-openmp/f77blas.h",
    # "/usr/include/lapack.h",
]

julia_root = "/home/kyungminlee/.local/pkg/julia-1.5.3"



util_list = [
    "openblas_get_config64_",
    "openblas_get_corename64_",
    "openblas_get_num_procs64_",
    "openblas_get_num_procs_64_",
    "openblas_get_num_threads64_",
    "openblas_get_num_threads_64_",
    "openblas_get_parallel64_",
    "openblas_get_parallel_64_",
    "openblas_set_num_threads64_",
    "openblas_set_num_threads_64_",
    "goto_set_num_threads64_",
    "lapack_make_complex_double64_",
    "lapack_make_complex_float64_",
]


function get_symbol_list(libpath::AbstractString; dynamic::Bool=true)
    if dynamic
        text = read(`nm -D "$(libpath)"`, String)
    else
        text = read(`nm "$(libpath)"`, String)
    end
    lines = [l for l in split(text, "\n") if length(l) >= 18 && l[18] == 'T']
    symbol_table = [tuple(split(l, " ")...) for l in lines]
    return [symbol_name
        for (symbol_address, symbol_type, symbol_name) in symbol_table
            if symbol_type == "T" || symbol_type == "t"
    ]
end


function get_stem(openblas64_symbol::AbstractString)
    # sym = lowercase(openblas64_symbol)
    sym = openblas64_symbol
    if endswith(sym, "_64_")
        sym = sym[1:end-4]
    elseif endswith(sym, "64_")
        sym = sym[1:end-3]
    elseif endswith(sym, "_")
        sym = sym[1:end-1]
    end
    # if startswith(sym, "mkl_")
    #     sym = sym[5:end]
    # end
    return sym
end

function get_function_decl_list(root_cursor)
    header = spelling(root_cursor)

    @info "parsing header $header"
    out = []
    for (i, child) in enumerate(children(root_cursor))
        filename(child) != header && continue  # skip if cursor filename is not in the headers to be wrapped
        kind(child) != Clang.CXCursor_FunctionDecl && continue # only function declaration

        child_spelling = spelling(child)
        isempty(child_spelling) && continue

        ftype = spelling(return_type(child))
        fname = child_spelling

        fparam_types = [spelling(argtype(type(child), i)) for i in 0:(argnum(child)-1)]
        fparam_names = [spelling(argument(child, i)) for i in 0:(argnum(child)-1)]
        for (iparam, name) in enumerate(fparam_names)
            if isempty(name)
                fparam_names[iparam] = "arg$(iparam)"
            end
        end
        stem = get_stem(fname)
        push!(out, (name=fname, return_type=ftype, param_types=fparam_types, param_names=fparam_names))
    end # for child
    return out
end

trans_units = parse_headers(
    mkl_headers,
    args=["-DMKL_ILP64=1", "-Dlapack_int=long long", "-DOPENBLAS_USE64BITINT=1"],
    includes=vcat(LIBCLANG_INCLUDE, CLANG_INCLUDE)
)

callee_decl_list = Dict()
for trans_unit in trans_units
    for decl in get_function_decl_list( getcursor(trans_unit) )
        stem = get_stem(decl.name)
        if haskey(callee_decl_list, stem)
            push!(callee_decl_list[stem], decl)
        else
            callee_decl_list[stem] = [decl]
        end
    end
end
# @show callee_decl_list


openblas64_exports = get_symbol_list("$julia_root/lib/julia/libopenblas64_.so")
ilp64_exports = vcat([get_symbol_list(lib; dynamic=false) for lib in mkl_libraries]...)


missing_caller_list = String[]
open("mklopenblas64.c", "w") do outfp
    println(outfp, "#include \"mklopenblas64.h\"")

    for caller in openblas64_exports
        endswith(caller, "64_") || continue # only wrap functions that end with 64_. No internal functions

        caller_stem = get_stem(caller)
        if !haskey(callee_decl_list, caller_stem)
            push!(missing_caller_list, caller)
            continue
        end

        select_callee_decl = nothing
        for callee_decl in callee_decl_list[caller_stem]
            if callee_decl.name ∈ ilp64_exports
                select_callee_decl = callee_decl
                break
            end
        end

        if isnothing(select_callee_decl)
            @warn "stem $caller_stem not found in ilp64_exports"
            continue
        end
        callee_decl = select_callee_decl

        ret = callee_decl.return_type == "void" ? "" : "return "
        fparams = join(["$t $a" for (t, a) in zip(callee_decl.param_types, callee_decl.param_names)], ", ")
        fargs = join(["$a" for a in callee_decl.param_names], ", ")
        println(outfp, """
            API_EXPORT
            $(callee_decl.return_type)
            $(caller)($fparams)
            {
                $(ret)$(callee_decl.name)($fargs);
            }
        """)
    end
end

# missing_caller_list = [x for x in missing_caller_list if x ∉ util_list]
@show missing_caller_list

