class Float
  # Because rb-gsl patches the Fixnum and Float classes with tons of
  # Kernel#kind_of?, multiplication and division become expensive when called
  # millions of times. Calls the original methods if argument is a Float;
  # otherwise calls the gsl alias
  # https://github.com/blackwinter/rb-gsl/blob/master/lib/gsl/oper.rb
  #
  alias :_gsl_mul :*
  alias :_gsl_div :/

  # Call #_orig_mul if other is a Float, else call gsl's alias
  def *(other)
    return _orig_mul(other) if other.is_a?(Float)

    _gsl_mul(other)
  end

  # Call #_orig_div if other is a Float, else call gsl's alias
  def /(other)
    return _orig_div(other) if other.is_a?(Float)

    _gsl_div(other)
  end
end
