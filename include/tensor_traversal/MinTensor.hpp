#pragma once
#include <array>
#include <type_traits>
#include <utility>
#include <numeric>
#include <algorithm>
#include <random>
#include <initializer_list>

template <class T>
constexpr typename std::add_const<T>::type & as_const(T& t) noexcept {
    return t;
}

template <typename ... Ts, typename R = typename std::common_type<Ts...>::type>
auto multiply_all(Ts && ... ts) -> R {
    static_assert(std::is_integral<R>::value, "[ERROR]: cannot call this function with non-integral types as args.");
    R result = 1;
    (void) std::initializer_list<int>{ (result *= ts, 0)... };
    return result;
}

template <typename T, std::size_t _dimensions>
struct matrix {
    T * _data;
    std::array<std::ptrdiff_t, _dimensions> _acc_dims;

    // Once you define one of the special member function you need to define the others as well
    ~matrix() { delete[] _data; }
        
    // Iterator constructor
    template <typename Iterator, typename ... Ts>
    matrix(Iterator first, Iterator last, Ts && ... ts) 
      :   _data(new T[multiply_all(std::forward<Ts>(ts)...)])
    {
      static_assert(sizeof...(ts) == _dimensions, "[ERROR]: Wrong number of arguments given\n");
      std::copy(first, last, _data);
      auto const dims = { std::forward<Ts>(ts)... };
      std::partial_sum(dims.begin(), dims.end(), _acc_dims.begin(), std::multiplies<std::ptrdiff_t>());
    }
            
    /* Access matrix indices through operator() */
    template <typename ... Idx>
    [[gnu::hot]] T const & operator() (Idx && ... idxs) const noexcept {
      static_assert(sizeof...(idxs) == _dimensions, "[ERROR]: Wrong number of dimensions given!");
      auto const v = { std::forward<Idx>(idxs)... };
      std::ptrdiff_t const index = std::inner_product(std::next(v.begin()), v.end(), _acc_dims.begin(), *v.begin());
      return _data[index];
    }

    /* Function is overloaded for both const and non-const versions
    * Note that, const version is faster so prefer that instead of non-const! */
    template <typename ... Args>
    T & operator() (Args&& ... args) { 
      return const_cast<T&>(as_const(*this).operator()(std::forward<Args>(args)...));
    }
};
