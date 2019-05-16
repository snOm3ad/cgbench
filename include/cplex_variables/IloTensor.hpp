#include <ilcplex/ilocplex.h>
#include <type_traits>
#include <array>
#include <numeric>
#include <initializer_list>

template <typename ... Args, typename R = typename std::common_type<Args...>::type>
auto multiply_all(Args && ... args) -> R {
    static_assert(std::is_integral<R>::value, "[ERROR]: cannot call this function with non-integral types.");
    R result = 1;
    (void) std::initializer_list<int>{ ( result *= args, 0)... };
    return result;
}

template <typename ... E, typename R = typename std::common_type<E...>::type>
auto make_array(E && ... elems) -> std::array<R, sizeof...(elems)> {
    return { std::forward<E>(elems)... }; 
}

namespace ilo {
    using dvar2d = IloArray<IloNumVarArray>;
    using dvar3d = IloArray<IloArray<IloNumVarArray>>;
    using dvar4d = IloArray<IloArray<IloArray<IloNumVarArray>>>;


    template <typename T, std::ptrdiff_t _dimensions>
    class tensor {
        static_assert (
            std::is_same<T, IloNumVarArray>::value or 
            std::is_same<T, IloRangeArray>::value,
            "[ERROR] cannot create ilo::tensor class with non cplex types."
        );

        T _variable;
        std::array<short, _dimensions> _acc_dims;

    public:
        tensor() = delete;
        tensor(tensor const &) = delete;

        template <typename ... Idxs>
        tensor(IloEnv env, Idxs && ... idxs)
            : _variable(env, multiply_all(std::forward<Idxs>(idxs)...), 0, IloInfinity)
        {
            auto const dimensions = { std::forward<Idxs>(idxs)... };
            std::partial_sum(dimensions.begin(), dimensions.end(), _acc_dims.begin(), std::multiplies<short>());
        }

        template <typename ... Idxs, typename R = typename std::common_type<Idxs...>::type>
        IloNumVar & operator()(Idxs && ... idxs) noexcept {
            static_assert(std::is_integral<R>::value, "[ERROR]: cannot call this function with non-integral types.");
            static_assert(sizeof...(idxs) == _dimensions, "[ERROR]: wrong number of dimensions given!");
            auto const v = { std::forward<Idxs>(idxs)... }; 
            std::ptrdiff_t idx = std::inner_product(std::next(v.begin()), v.end(), _acc_dims.begin(), *v.begin());
            return _variable[idx];
        }
    };
}
