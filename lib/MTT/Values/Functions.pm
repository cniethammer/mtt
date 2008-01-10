#!/usr/bin/env perl
#
# Copyright (c) 2005-2006 The Trustees of Indiana University.
#                         All rights reserved.
# Copyright (c) 2006-2007 Cisco Systems, Inc.  All rights reserved.
# Copyright (c) 2007      Sun Microsystems, Inc.  All rights reserved.
# $COPYRIGHT$
# 
# Additional copyrights may follow
# 
# $HEADER$
#

package MTT::Values::Functions;

use strict;
use File::Find;
use File::Temp qw(tempfile);
use File::Basename;
use Sys::Hostname;
use MTT::Messages;
use MTT::Globals;
use MTT::Files;
use MTT::FindProgram;
use MTT::Lock;
use MTT::Util;
use MTT::INI;
use Data::Dumper;
use Cwd;

# Do NOT use MTT::Test::Run here, even though we use some
# MTT::Test::Run values below.  This will create a "use loop".  Be
# confident that we'll get the values as appropriate when we need them
# through other "use" statements.

#--------------------------------------------------------------------------

# Returns the result value (array or scalar) of a perl eval
sub perl {
    my $funclet = '&' . FuncName((caller(0))[3]);
    Debug("&perl $funclet: got @_\n");

    my $cmd = join(/ /, @_);
    Debug( "CMD: $cmd\n");

    # Loosen stricture here to allow &perl() to 
    # have its own variables
    no strict;
    my $ret = eval $cmd;
    use strict;
    Debug("ERROR: $?\n");

    if (ref($ret) =~ /array/i) {
        Debug("$funclet: returning array [@$ret]\n");
    } else {
        Debug("$funclet: returning scalar $ret\n");
    }

    return $ret;
}

#--------------------------------------------------------------------------

# Returns the result_stdout of running a shell command
sub shell {
    Debug("&shell: got @_\n");
    my $cmd = join(/ /, @_);
    open SHELL, "$cmd|";
    my $ret;
    while (<SHELL>) {
        $ret .= $_;
    }
    chomp($ret);
    Debug("&shell: returning $ret\n");
    return $ret;
}

#--------------------------------------------------------------------------

# Runs MTT::Messages::Verbose
sub verbose {
    MTT::Messages::Verbose(@_);
    return undef;
}

#--------------------------------------------------------------------------

# Runs MTT::Messages::Debug
sub debug {
    MTT::Messages::Debug(@_);
    return undef;
}

#--------------------------------------------------------------------------

# Runs print
sub print {
    print(@_);
    return undef;
}

#--------------------------------------------------------------------------

# Return the sum of all parameters
sub sum {
    my $array = _get_array_ref(\@_);
    Debug("&sum got: @$array\n");
    return "0"
        if (!defined($array));

    my $sum = 0;
    foreach my $val (@$array) {
        $sum += $val;
    }

    Debug("&sum returning: $sum\n");
    return $sum;
}

#--------------------------------------------------------------------------

# Return the product of all parameters
sub multiply {
    my $array = _get_array_ref(\@_);
    Debug("&multiply got: @$array\n");
    return "0"
        if (!defined($array));

    my $prod = 1;
    foreach my $val (@$array) {
        $prod *= $val;
    }

    Debug("&multiply returning: $prod\n");
    return $prod;
}

#--------------------------------------------------------------------------

# Return all the squares
sub squares {
    Debug("&squares got: @_\n");
    my ($min, $max) = @_;

    my @ret;
    my $val = $min;
    while ($val <= $max) {
        push(@ret, $val * $val);
        ++$val;
    }

    return \@ret;
}

#--------------------------------------------------------------------------

# Similar to the PHP array_fill function
sub array_fill {
    Debug("&array_fill got: @_\n");
    my ($num, $value) = @_;

    my @ret;
    foreach (1..$num) {
        push(@ret, $value);
    }

    Debug("&array_fill returning: @ret\n");
    return \@ret;
}

#--------------------------------------------------------------------------

# Returns the log of a number in base N
sub log {
    Debug("&log got: @_\n");
    my ($base, $val) = @_;
    return log($val) / log($base);
}

#--------------------------------------------------------------------------

# Return all the powers of a given base from [base^min, base^max]
sub pow {
    Debug("&pow got: @_\n");
    my ($base, $min, $max) = @_;

    my @ret;
    my $val = $min;
    while ($val <= $max) {
        push(@ret, $base ** $val);
        ++$val;
    }

    return \@ret;
}

#--------------------------------------------------------------------------

# Return a list of prime numbers between min and max
sub prime {
    Debug("&prime got: @_\n");
    my ($min, $max) = @_;

    my @primes = qw/  
      2      3      5      7     11     13     17     19     23     29 
     31     37     41     43     47     53     59     61     67     71 
     73     79     83     89     97    101    103    107    109    113 
    127    131    137    139    149    151    157    163    167    173 
    179    181    191    193    197    199    211    223    227    229 
    233    239    241    251    257    263    269    271    277    281 
    283    293    307    311    313    317    331    337    347    349 
    353    359    367    373    379    383    389    397    401    409 
    419    421    431    433    439    443    449    457    461    463 
    467    479    487    491    499    503    509    521    523    541 
    547    557    563    569    571    577    587    593    599    601 
    607    613    617    619    631    641    643    647    653    659 
    661    673    677    683    691    701    709    719    727    733 
    739    743    751    757    761    769    773    787    797    809 
    811    821    823    827    829    839    853    857    859    863 
    877    881    883    887    907    911    919    929    937    941 
    947    953    967    971    977    983    991    997   1009   1013 
   1019   1021   1031   1033   1039   1049   1051   1061   1063   1069 
   1087   1091   1093   1097   1103   1109   1117   1123   1129   1151 
   1153   1163   1171   1181   1187   1193   1201   1213   1217   1223 
   1229   1231   1237   1249   1259   1277   1279   1283   1289   1291 
   1297   1301   1303   1307   1319   1321   1327   1361   1367   1373 
   1381   1399   1409   1423   1427   1429   1433   1439   1447   1451 
   1453   1459   1471   1481   1483   1487   1489   1493   1499   1511 
   1523   1531   1543   1549   1553   1559   1567   1571   1579   1583 
   1597   1601   1607   1609   1613   1619   1621   1627   1637   1657 
   1663   1667   1669   1693   1697   1699   1709   1721   1723   1733 
   1741   1747   1753   1759   1777   1783   1787   1789   1801   1811 
   1823   1831   1847   1861   1867   1871   1873   1877   1879   1889 
   1901   1907   1913   1931   1933   1949   1951   1973   1979   1987 
   1993   1997   1999   2003   2011   2017   2027   2029   2039   2053 
   2063   2069   2081   2083   2087   2089   2099   2111   2113   2129 
   2131   2137   2141   2143   2153   2161   2179   2203   2207   2213 
   2221   2237   2239   2243   2251   2267   2269   2273   2281   2287 
   2293   2297   2309   2311   2333   2339   2341   2347   2351   2357 
   2371   2377   2381   2383   2389   2393   2399   2411   2417   2423 
   2437   2441   2447   2459   2467   2473   2477   2503   2521   2531 
   2539   2543   2549   2551   2557   2579   2591   2593   2609   2617 
   2621   2633   2647   2657   2659   2663   2671   2677   2683   2687 
   2689   2693   2699   2707   2711   2713   2719   2729   2731   2741 
   2749   2753   2767   2777   2789   2791   2797   2801   2803   2819 
   2833   2837   2843   2851   2857   2861   2879   2887   2897   2903 
   2909   2917   2927   2939   2953   2957   2963   2969   2971   2999 
   3001   3011   3019   3023   3037   3041   3049   3061   3067   3079 
   3083   3089   3109   3119   3121   3137   3163   3167   3169   3181 
   3187   3191   3203   3209   3217   3221   3229   3251   3253   3257 
   3259   3271   3299   3301   3307   3313   3319   3323   3329   3331 
   3343   3347   3359   3361   3371   3373   3389   3391   3407   3413 
   3433   3449   3457   3461   3463   3467   3469   3491   3499   3511 
   3517   3527   3529   3533   3539   3541   3547   3557   3559   3571 
   3581   3583   3593   3607   3613   3617   3623   3631   3637   3643 
   3659   3671   3673   3677   3691   3697   3701   3709   3719   3727 
   3733   3739   3761   3767   3769   3779   3793   3797   3803   3821 
   3823   3833   3847   3851   3853   3863   3877   3881   3889   3907 
   3911   3917   3919   3923   3929   3931   3943   3947   3967   3989 
   4001   4003   4007   4013   4019   4021   4027   4049   4051   4057 
   4073   4079   4091   4093   4099   4111   4127   4129   4133   4139 
   4153   4157   4159   4177   4201   4211   4217   4219   4229   4231 
   4241   4243   4253   4259   4261   4271   4273   4283   4289   4297 
   4327   4337   4339   4349   4357   4363   4373   4391   4397   4409 
   4421   4423   4441   4447   4451   4457   4463   4481   4483   4493 
   4507   4513   4517   4519   4523   4547   4549   4561   4567   4583 
   4591   4597   4603   4621   4637   4639   4643   4649   4651   4657 
   4663   4673   4679   4691   4703   4721   4723   4729   4733   4751 
   4759   4783   4787   4789   4793   4799   4801   4813   4817   4831 
   4861   4871   4877   4889   4903   4909   4919   4931   4933   4937 
   4943   4951   4957   4967   4969   4973   4987   4993   4999   5003 
   5009   5011   5021   5023   5039   5051   5059   5077   5081   5087 
   5099   5101   5107   5113   5119   5147   5153   5167   5171   5179 
   5189   5197   5209   5227   5231   5233   5237   5261   5273   5279 
   5281   5297   5303   5309   5323   5333   5347   5351   5381   5387 
   5393   5399   5407   5413   5417   5419   5431   5437   5441   5443 
   5449   5471   5477   5479   5483   5501   5503   5507   5519   5521 
   5527   5531   5557   5563   5569   5573   5581   5591   5623   5639 
   5641   5647   5651   5653   5657   5659   5669   5683   5689   5693 
   5701   5711   5717   5737   5741   5743   5749   5779   5783   5791 
   5801   5807   5813   5821   5827   5839   5843   5849   5851   5857 
   5861   5867   5869   5879   5881   5897   5903   5923   5927   5939 
   5953   5981   5987   6007   6011   6029   6037   6043   6047   6053 
   6067   6073   6079   6089   6091   6101   6113   6121   6131   6133 
   6143   6151   6163   6173   6197   6199   6203   6211   6217   6221 
   6229   6247   6257   6263   6269   6271   6277   6287   6299   6301 
   6311   6317   6323   6329   6337   6343   6353   6359   6361   6367 
   6373   6379   6389   6397   6421   6427   6449   6451   6469   6473 
   6481   6491   6521   6529   6547   6551   6553   6563   6569   6571 
   6577   6581   6599   6607   6619   6637   6653   6659   6661   6673 
   6679   6689   6691   6701   6703   6709   6719   6733   6737   6761 
   6763   6779   6781   6791   6793   6803   6823   6827   6829   6833 
   6841   6857   6863   6869   6871   6883   6899   6907   6911   6917 
   6947   6949   6959   6961   6967   6971   6977   6983   6991   6997 
   7001   7013   7019   7027   7039   7043   7057   7069   7079   7103 
   7109   7121   7127   7129   7151   7159   7177   7187   7193   7207
   7211   7213   7219   7229   7237   7243   7247   7253   7283   7297 
   7307   7309   7321   7331   7333   7349   7351   7369   7393   7411 
   7417   7433   7451   7457   7459   7477   7481   7487   7489   7499 
   7507   7517   7523   7529   7537   7541   7547   7549   7559   7561 
   7573   7577   7583   7589   7591   7603   7607   7621   7639   7643 
   7649   7669   7673   7681   7687   7691   7699   7703   7717   7723 
   7727   7741   7753   7757   7759   7789   7793   7817   7823   7829 
   7841   7853   7867   7873   7877   7879   7883   7901   7907   7919/;
   
    my @ret;
    foreach my $prime (@primes) {
        next if ($prime < $min);
        last if ($prime > $max);
        push(@ret, $prime);
    }

    Debug("&prime returning: @ret\n");
    return \@ret;
}

#--------------------------------------------------------------------------

# Return the minimum value of all parameters
sub min {
    my $array = _get_array_ref(\@_);
    Debug("&min got: @$array\n");
    return "0"
        if (!defined($array));

    my $min = shift(@$array);
    foreach my $val (@$array) {
        $min = $val
            if ($val < $min)
    }

    Debug("&min returning: $min\n");
    return $min;
}

#--------------------------------------------------------------------------

# Return the maximum value of all parameters
sub max {
    my $array = _get_array_ref(\@_);
    Debug("&max got: @$array\n");
    return "0"
        if (!defined($array));

    my $max = shift(@$array);
    foreach my $val (@$array) {
        $max = $val
            if ($val > $max)
    }

    Debug("&max returning: $max\n");
    return $max;
}

#--------------------------------------------------------------------------

# Return 1 if all the values are not equal, 0 otherwise.  If there are
# no arguments, return 1.
sub ne {
    my $array = _get_array_ref(\@_);
    Debug("&ne got: @$array\n");
    return "0"
        if (!defined($array));

    my $first = shift(@$array);
    do {
        my $next = shift(@$array);
        if ($first eq $next) {
            Debug("&ne: returning 0\n");
            return "0";
        }
    } while (@$array);
    Debug("&ne: returning 1\n");
    return "1";
}

#--------------------------------------------------------------------------

# Return 1 if the first argument is greater than the second
sub gt {
    my $array = _get_array_ref(\@_);
    Debug("&gt got: @$array\n");
    return "0"
        if (!defined($array));

    my $a = shift(@$array);
    my $b = shift(@$array);

    if ($a > $b) {
        Debug("&gt: returning 1\n");
        return "1";
    } else {
        Debug("&gt: returning 0\n");
        return "0";
    }
}

#--------------------------------------------------------------------------

# Return 1 if the first argument is greater than or equal to the second
sub ge {
    my $array = _get_array_ref(\@_);
    Debug("&ge got: @$array\n");
    return "0"
        if (!defined($array));

    my $a = shift(@$array);
    my $b = shift(@$array);

    if ($a >= $b) {
        Debug("&ge: returning 1\n");
        return "1";
    } else {
        Debug("&ge: returning 0\n");
        return "0";
    }
}

#--------------------------------------------------------------------------

# Return 1 if the first argument is less than the second
sub lt {
    my $array = _get_array_ref(\@_);
    Debug("&lt got: @$array\n");
    return "0"
        if (!defined($array));

    my $a = shift(@$array);
    my $b = shift(@$array);

    if ($a < $b) {
        Debug("&lt: returning 1\n");
        return "1";
    } else {
        Debug("&lt: returning 0\n");
        return "0";
    }
}

#--------------------------------------------------------------------------

# Return 1 if the first argument is less than or equal to the second
sub le {
    my $array = _get_array_ref(\@_);
    Debug("&le got: @$array\n");
    return "0"
        if (!defined($array));

    my $a = shift(@$array);
    my $b = shift(@$array);

    if ($a <= $b) {
        Debug("&le: returning 1\n");
        return "1";
    } else {
        Debug("&le: returning 0\n");
        return "0";
    }
}

#--------------------------------------------------------------------------

# Return 1 if all the values are equal, 0 otherwise.  If there are no
# arguments, return 1.
sub eq {
    my $array = _get_array_ref(\@_);
    Debug("&eq got: @$array\n");
    return "1"
        if (!defined($array));

    my $first = shift(@$array);
    do {
        my $next = shift(@$array);;
        if ($first ne $next) {
            Debug("&eq: returning 0\n");
            return "0";
        }
    } while (@$array);
    Debug("&eq: returning 1\n");
    return "1";
}

#--------------------------------------------------------------------------

# Return "1" if the first arg matches the second arg (the regexp)
sub regexp {
    my $funclet = "regexp";
    Debug("&$funclet got: @_\n");
    return "1"
        if (!@_);

    my $string = shift;
    my $pattern = shift;

    if ($string =~ /$pattern/) {
        Debug("$funclet: returning 1\n");
        return "1";
    }
    Debug("$funclet: returning 0\n");
    return "0";
}

#--------------------------------------------------------------------------

# Return the captured group in the regular expression
# E.g.,:
#   &regexp_capture("foo bar", "\w+ (\w+)")
#   returns "bar"
sub regexp_capture {
    my $funclet = "regexp_capture";
    Debug("&$funclet got: @_\n");
    return ""
        if (!@_);

    my $string = shift;
    my $pattern = shift;

    if ($string =~ /$pattern/) {
        Debug("$funclet: returning $+\n");
        return $+;
    }
    Debug("$funclet: returning \"\"\n");
    return "";
}

#--------------------------------------------------------------------------

sub and {
    my $array = _get_array_ref(\@_);
    Debug("&and got: @$array\n");
    return "1"
        if (!@$array);

    do {
        my $val = shift(@$array);
        if (!$val) {
            Debug("&and: returning 0\n");
            return "0";
        }
    } while (@$array);
    Debug("&and: returning 1\n");
    return "1";
}

#--------------------------------------------------------------------------

# Return 1 if any of the values are true, 0 otherwise.  If there are no
# arguments, return 1.
sub or {
    my $array = _get_array_ref(\@_);
    Debug("&or got: @$array\n");
    return "1"
        if (!@$array);

    do {
        my $val = shift(@$array);
        if ($val) {
            Debug("&or: returning 1\n");
            return "1";
        }
    } while (@$array);
    Debug("&or: returning 0\n");
    return "0";
}

#--------------------------------------------------------------------------

# If the first argument is true (nonzero), return the 2nd argument.
# Otherwise, return the 3rd argument.
sub if {
    Debug("&if got: @_\n");
    my ($t, $a, $b) = @_;

    my $ret = $t ? $a : $b;
    Debug("&if returning $ret\n");
    return $ret;
}

#--------------------------------------------------------------------------

# Return a reference to all the strings passed in as @_
sub enumerate {
    my $array = _get_array_ref(\@_);
    Debug("&enumerate got: @$array\n");

    my @ret;
    foreach my $arg (@$array) {
        push(@ret, $arg);
    }
    return \@ret;
}

#--------------------------------------------------------------------------

# Return a reference to all the strings passed in as @_
sub split {
    Debug("&split got: @_\n");
    my $str = shift;
    my $n = shift;

    my @ret = split(/\s+/, $str);
    if (defined($n)) {
        return $ret[$n];
    } else {
        return \@ret;
    }
}

#--------------------------------------------------------------------------

# Prepend a string to a string or an array of stringd
sub prepend {
    my $str = shift;
    my $array = _get_array_ref(\@_);
    Debug("&prepend got $str @$array\n");
    return undef
        if (!defined($array));

    # $array is now guaranteed to be a reference to an array.
    my @ret;
    my $val;
    push(@ret, $str . $val)
        while ($val = shift @$array);

    return \@ret;
}


#--------------------------------------------------------------------------

# Join all the strings passed into one string and return it
sub stringify {
    my $array = _get_array_ref(\@_);
    Debug("&stringify got: @$array\n");

    my $str;
    while (@$array) {
        my $val = shift(@$array);
        if (ref($val) =~ /array/i) {
            $str .= stringify(@$val);
        } elsif ("" eq ref($val)) {
            $str .= $val;
        } else {
            Warn("Got an argument to &stringify() that was not understood; ignored\n");
        }
    }
    Debug("&stringify returning: $str\n");
    return $str;
}

#--------------------------------------------------------------------------

sub preg_replace {
    Debug("&preg_replace got: @_\n");
    my ($pattern, $replacement, $subject) = @_;

    my $ret = $subject;
    $ret =~ s/$pattern/$replacement/;
    Verbose("&preg_replace returning: $ret\n");
}

#--------------------------------------------------------------------------

sub strstr {
    Debug("&strstr got: @_\n");
    my ($s1, $s2) = @_;

    if ($s2 =~ s/($s1.*)/\1/) {
        Debug("&strstr returning: $s2\n");
        return $s2;
    } else {
        Debug("&strstr returning: <undef>\n");
        return undef;
    }
}

#--------------------------------------------------------------------------

# First argument is the lower bound, second argument is upper bound,
# third [optional] argument is the stride (is 1 if not specified).
# Return a reference to all values starting with $lower and <=$upper
# with the given $stride.  E.g., &step(3, 10, 2) returns 3, 5, 7, 9.
sub step {
    Debug("&step got: @_\n");

    my $lower = shift;
    my $upper = shift;
    my $step = shift;
    $step = 1
        if (!$step);

    my @ret;
    while ($lower <= $upper) {
        push(@ret, "$lower");
        $lower += $step;
    }
    return \@ret;
}

#--------------------------------------------------------------------------

# Get the platform type
sub get_platform_type {
    Debug("&get_platform_type\n");
    my $ret = whatami("-t");
    return $ret
        if (defined($ret));

    my $x = MTT::DoCommand::Cmd(1, "uname -p");
    if (0 == $x->{return_status}) {
        chomp($x->{result_stdout});
        return $x->{result_stdout};
    }
    return "unknown";
}

# Get the platform hardware
sub get_platform_hardware {
    Debug("&get_platform_hardware\n");
    my $ret = whatami("-m");
    return $ret
        if (defined($ret));

    my $x = MTT::DoCommand::Cmd(1, "uname -m");
    if (0 == $x->{return_status}) {
        chomp($x->{result_stdout});
        return $x->{result_stdout};
    }
    return "unknown";
}

# Get the OS name
sub get_os_name {
    Debug("&get_os_name\n");
    my $ret = whatami("-n");
    return $ret
        if (defined($ret));

    my $x = MTT::DoCommand::Cmd(1, "uname -s");
    if (0 == $x->{return_status}) {
        chomp($x->{result_stdout});
        return $x->{result_stdout};
    }

    return "unknown";
}

# Get the OS version
sub get_os_version {
    Debug("&get_os_version\n");
    my $ret = whatami("-r");
    return $ret
        if (defined($ret));

    my $x = MTT::DoCommand::Cmd(1, "uname -v");
    if (0 == $x->{return_status}) {
        chomp($x->{result_stdout});
        return $x->{result_stdout};
    }
    return "unknown";
}

#--------------------------------------------------------------------------

# Run the "whatami" command
my $_whatami;
sub whatami {
    Debug("&whatami got: @_\n");

    # Find whatami
    if (!defined($_whatami)) {
        my $dir = MTT::FindProgram::FindZeroDir();
        $_whatami = "$dir/whatami/whatami"
            if (-x "$dir/whatami/whatami");
        $_whatami = "$dir/whatami"
            if (!defined($_whatami) && -x "$dir/whatami");
        foreach my $dir (split(/:/, $ENV{PATH})) {
            if (!defined($_whatami) && -x "$dir/whatami") {
                $_whatami = "$dir/whatami";
                last;
            }
        }
        $_whatami = $ENV{MTT_WHATAMI}
            if (!defined($_whatami) && exists($ENV{MTT_WHATAMI}) &&
                -x $ENV{MTT_WHATAMI});
        return undef
            if (!defined($_whatami));
        Debug("Found whatami: $_whatami\n");
    }

    # Run the whatami program
    my $x = MTT::DoCommand::Cmd(1, "$_whatami @_");
    return undef
        if (0 != $x->{exit_status});
    chomp($x->{result_stdout});
    return $x->{result_stdout};
}

#--------------------------------------------------------------------------

# Return the current np value from a running test.
sub test_command_line {
    Debug("&test_command_line returning: $MTT::Test::Run::test_command_line\n");

    return $MTT::Test::Run::test_command_line;
}

#--------------------------------------------------------------------------

# Return the current np value from a running test.
sub test_np {
    Debug("&test_np returning: $MTT::Test::Run::test_np\n");

    return $MTT::Test::Run::test_np;
}

#--------------------------------------------------------------------------

# Return the current prefix value from a running test
sub test_prefix {
    Debug("&test_prefix returning: $MTT::Test::Run::test_prefix\n");

    return $MTT::Test::Run::test_prefix;
}

#--------------------------------------------------------------------------

# Return the current executable value from a running test
sub test_executable {
    Debug("&test_executable returning: $MTT::Test::Run::test_executable\n");

    return $MTT::Test::Run::test_executable;
}

#--------------------------------------------------------------------------

# Return the current argv (excluding $argv[0]) from a running test
sub test_argv {
    Debug("&test_params returning $MTT::Test::Run::test_argv\n");

    return $MTT::Test::Run::test_argv;
}

#--------------------------------------------------------------------------

# Return whether the last test run was terminated by a signal
sub test_alloc {
    Debug("&test_alloc returning $MTT::Test::Run::test_alloc\n");

    return $MTT::Test::Run::test_alloc;
}

#--------------------------------------------------------------------------

# Return the exit exit_status from the last test run
# DEPRECATED
sub test_exit_status {
    Debug("&test_exit_status: this function is deprecated; please call test_wexitstatus()\n");
    return test_wexitstatus();
}

#--------------------------------------------------------------------------

# Return whether the last test run terminated normally
sub test_wifexited {
    my $ret = MTT::DoCommand::wifexited($MTT::Test::Run::test_exit_status);
    Debug("&test_wifexited returning: $ret\n");
    return $ret ? "1" : "0";
}

#--------------------------------------------------------------------------

# Return the exit status from the last test run
sub test_wexitstatus {
    my $ret = MTT::DoCommand::wexitstatus($MTT::Test::Run::test_exit_status);
    Debug("&test_wexitstatus returning $ret\n");
    return "$ret";
}

#--------------------------------------------------------------------------

# Return whether the last test run was terminated by a signal
sub test_wifsignaled {
    my $ret = MTT::DoCommand::wifsignaled($MTT::Test::Run::test_exit_status);
    Debug("&test_widsignaled returning: $ret\n");
    return $ret ? "1" : "0";
}

#--------------------------------------------------------------------------

# Return whether the last test run was terminated by a signal
sub test_wtermsig {
    my $ret = MTT::DoCommand::wtermsig($MTT::Test::Run::test_exit_status);
    Debug("&test_wtermsig returning: $ret\n");
    return "$ret";
}

#--------------------------------------------------------------------------

# Return whether the last DoCommand::Cmd[Script] terminated normally
sub cmd_wifexited {
    my $ret = MTT::DoCommand::wifexited($MTT::DoCommand::last_exit_status);
    Debug("&test_wifexited returning: $ret\n");
    return $ret ? "1" : "0";
}

#--------------------------------------------------------------------------

# Return the exit status from the last DoCommand::Cmd[Script]
sub cmd_wexitstatus {
    my $ret = MTT::DoCommand::wexitstatus($MTT::DoCommand::last_exit_status);
    Debug("&test_wexitstatus returning $ret\n");
    return "$ret";
}

#--------------------------------------------------------------------------

# Return whether the last DoCommand::Cmd[Script] was terminated by a signal
sub cmd_wifsignaled {
    my $ret = MTT::DoCommand::wifsignaled($MTT::DoCommand::last_exit_status);
    Debug("&test_widsignaled returning: $ret\n");
    return $ret ? "1" : "0";
}

#--------------------------------------------------------------------------

# Return whether the last DoCommand::Cmd[Script] was terminated by a signal
sub cmd_wtermsig {
    my $ret = MTT::DoCommand::wtermsig($MTT::DoCommand::last_exit_status);
    Debug("&test_wtermsig returning: $ret\n");
    return "$ret";
}

#--------------------------------------------------------------------------

# Return a reference to an array of strings of the contents of a file
sub cat {
    my $array = _get_array_ref(\@_);
    Debug("&cat: @$array\n");

    my @ret;
    foreach my $file (@$array) {
        if (-f $file) {
            open(FILE, $file);
            while (<FILE>) {
                chomp;
                push(@ret, $_);
            }
            close(FILE);
        }
    }

    Debug("&cat returning: @ret\n");
    return \@ret;
}

#--------------------------------------------------------------------------

# Traverse a tree (or a bunch of trees) and return all the executables
# found
my @find_executables_data;
sub find_executables {
    my $array = _get_array_ref(\@_);
    Debug("&find_executables got @$array\n");

    @find_executables_data = ();
    my @dirs;
    foreach my $d (@$array) {
        push(@dirs, $d)
            if ("" ne $d);
    }
    File::Find::find(\&find_executables_sub, @dirs);

    Debug("&find_exectuables returning: @find_executables_data\n");
    return \@find_executables_data;
}

sub find_executables_sub {
    # Don't process directories and links, and don't recurse down
    # "special" directories
    if ( -l $_ ) { return; }
    if ( -d $_ ) { 
        if ((/\.svn/) || (/\.deps/) || (/\.libs/) || (/autom4te\.cache/)) {
            $File::Find::prune = 1;
        }
        return;
    }

    # $File::Find::name is the path relative to the starting point.
    # $_ contains the file's basename.  The code automatically changes
    # to the processed directory, so we want to examine $_.
    push(@find_executables_data, $File::Find::name)
        if (-x $_);
}

#--------------------------------------------------------------------------

# Traverse a tree (or a bunch of trees) and return all the files
# matching a regexp
my @find_data;
my $find_regexp;
sub find {
    my $array = _get_array_ref(\@_);
    Debug("&find got @$array\n");

    $find_regexp = shift(@$array);
    @find_data = ();
    my @dirs;
    foreach my $d (@$array) {
        push(@dirs, $d)
            if ("" ne $d);
    }
    File::Find::find(\&find_sub, @dirs);

    Debug("&find returning: @find_data\n");
    return \@find_data;
}

sub find_sub {
    # Don't process directories and links, and don't recurse down
    # "special" directories
    if ( -l $_ ) { return; }
    if ( -d $_ ) { 
        if ((/\.svn/) || (/\.deps/) || (/\.libs/) || (/autom4te\.cache/)) {
            $File::Find::prune = 1;
        }
        return;
    }

    # $File::Find::name is the path relative to the starting point.
    # $_ contains the file's basename.  The code automatically changes
    # to the processed directory, so we want to examine $_.
    push(@find_data, $File::Find::name)
        if ($File::Find::name =~ $find_regexp);
}

#--------------------------------------------------------------------------

# return File::Basename::dirname()
sub dirname {
    my($str) = @_;
    return File::Basename::dirname($str);
}

# return cwd()
sub cwd {
    return cwd();
}

# return cwd()
sub pwd {
    return cwd();
}

# Just like the "which" shell command
sub which {
    my ($str) = @_;
    my @arr = split(/ /, $str);
    return FindProgram(@arr);
}

# return File::Basename::basename()
sub basename {
    my($str) = @_;
    return File::Basename::basename($str);
}

# return Sys::Hostname::hostname()
sub hostname {
    return Sys::Hostname::hostname();
}

#--------------------------------------------------------------------------

# Deprecated name for env_max_procs
sub rm_max_procs {
    Warning("You are using a deprecated funclet name in your INI file: &rm_max_procs().  Please update to use the new functlet name: &env_max_procs().  This old name will disappear someday.\n");
    return env_max_procs();
}

#--------------------------------------------------------------------------

# Return the name of the run-time enviornment that we're using.  The
# only difference between rm_name() and env_name() is that env_name()
# may also return "hostlist" or "hostfile", whereas rm_name() will
# return "none" for those cases (because there is no resource
# manager).
sub rm_name {
    Debug("&rm_name\n");

    my $ret = env_name();
    return "none"
        if ("hostlist" eq $ret || "hostfile" eq $ret);

    return $ret;
}

#--------------------------------------------------------------------------

# Return the name of the run-time enviornment that we're using
sub env_name {
    Debug("&env_name\n");

    # Resource managers
    return "SLURM"
        if slurm_job();
    return "TM"
        if pbs_job();
    return "N1GE"
        if n1ge_job();
    return "loadleveler"
        if loadleveler_job();

    # Hostfile
    return "hostfile"
        if have_hostfile();

    # Hostlist
    return "hostlist"
        if have_hostlist();

    # No clue, Jack...
    return "unknown";
}

#--------------------------------------------------------------------------

# Find the max procs that we can run with.  Check several things in
# order:
#
# - Various resource managers
# - if a global hostfile was specified
# - if a global hostlist was specified
# - if a global max_np was specified
#
# If none of those things are found, return "2".
sub env_max_procs {
    Debug("&env_max_procs\n");

    # Manual specification of max_np
    return ini_max_procs()
        if have_ini_max_procs();

    # Resource managers
    return slurm_max_procs()
        if slurm_job();
    return pbs_max_procs()
        if pbs_job();
    return n1ge_max_procs()
        if n1ge_job();
    return loadleveler_max_procs()
        if loadleveler_job();

    # Hostfile
    return hostfile_max_procs()
        if have_hostfile();

    # Hostlist
    return hostlist_max_procs()
        if have_hostlist();

    # Not running under anything; just return 2.
    return "2";
}

#--------------------------------------------------------------------------

# Find the max number of hosts that we can run with. 
sub env_max_hosts {
    Debug("&env_max_hosts\n");

    my $hosts = env_hosts(1);
    my @hosts = split(/,/, $hosts);
    Debug("&env_max_hosts: returning " . $#hosts + 1 . "\n");
    return $#hosts + 1;
}

#--------------------------------------------------------------------------

# Find the hosts that we can run with
sub env_hosts {
    my ($want_unique) = @_;
    Debug("&env_hosts: want_unique=$want_unique\n");

    # Resource managers
    my $ret;
    if (slurm_job()) {
        $ret = slurm_hosts();
    } elsif (pbs_job()) {
        $ret = pbs_hosts();
    } elsif (n1ge_job()) {
        $ret = n1ge_hosts();
    } elsif (loadleveler_job()) {
        $ret = loadleveler_hosts();
    }

    # Hostfile
    elsif (have_hostfile()) {
        $ret = hostfile_hosts();
    }

    # Hostlist
    elsif (have_hostlist()) {
        $ret = hostlist_hosts();
    }

    # Not running under anything; just return the localhost name
    else {
        my $ret = `hostname`;
        chomp($ret);
    }

    # Do we need to uniq-ify the list?
    if ($want_unique) {
        my @h = split(/,/, $ret);
        my %hmap;
        foreach my $h (@h) {
            $hmap{$h} = 1;
        }
        $ret = join(',', keys(%hmap));
    }

    Debug("&env_hosts returning: $ret\n");
    return "$ret";
}

#--------------------------------------------------------------------------

# Return "1" if we have a hostfile; "0" otherwise
sub have_hostfile {
    my $ret = (defined $MTT::Globals::Values->{hostfile}) ? "1" : "0";
    Debug("&have_hostfile returning $ret\n");
    return $ret;
}

#--------------------------------------------------------------------------

# If we have a hostfile, return it.  Otherwise, return the empty string.
sub hostfile {
    Debug("&hostfile: $MTT::Globals::Values->{hostfile}\n");

    if (have_hostfile) {
        return $MTT::Globals::Values->{hostfile};
    } else {
        return "";
    }
}

#--------------------------------------------------------------------------

# If we have a hostfile, return its max procs count
sub hostfile_max_procs {
    Debug("&hostfile_max_procs\n");

    return "0"
        if (!have_hostfile());

    Debug("&hostfile_max_procs returning $MTT::Globals::Values->{hostfile_max_np}\n");
    return $MTT::Globals::Values->{hostfile_max_np};
}

#--------------------------------------------------------------------------

# If we have a hostfile, return its hosts
sub hostfile_hosts {
    Debug("&hostfile_hosts\n");

    return ""
        if (!have_hostfile());

    # Return the uniq'ed contents of the hostfile

    open (FILE, $MTT::Globals::Values->{hostfile}) || return "";
    my $lines;
    while (<FILE>) {
        chomp;
        $lines->{$_} = 1;
    }

    my @hosts = sort(keys(%$lines));
    my $hosts = join(",", @hosts);
    Debug("&hostfile_hosts returning $hosts\n");
    return "$hosts";
}

#--------------------------------------------------------------------------

# Return "1" if we have a hostfile; "0" otherwise
sub have_hostlist {
    my $ret = (defined $MTT::Globals::Values->{hostlist}) ? "1" : "0";
    Debug("&have_hostlist: returning $ret\n");
    return $ret;
}

#--------------------------------------------------------------------------

# If we have a hostlist, return it.  Otherwise, return the empty string.
sub hostlist {
    Debug("&hostlist: $MTT::Globals::Values->{hostlist}\n");

    return hostlist_hosts(@_);
}

#--------------------------------------------------------------------------

# If we have a hostlist, return its max procs count
sub hostlist_max_procs {
    Debug("&hostlist_max_procs\n");

    return "0"
        if (!have_hostlist());

    Debug("&hostlist_max_procs returning $MTT::Globals::Values->{hostlist_max_np}\n");
    return $MTT::Globals::Values->{hostlist_max_np};
}

#--------------------------------------------------------------------------

# If we have a hostlist, return its hosts
sub hostlist_hosts {
    Debug("&hostlist_hosts\n");
    my $delimiter = shift;

    return ""
        if (!have_hostlist());

    if (defined($delimiter)) {
        my @hosts = split(/,/, $MTT::Globals::Values->{hostlist});
        my $ret = join($delimiter, @hosts);
        Debug("&hostlist_hosts (delimiter=$delimiter) returning $ret\n");
        return $ret;
    } else {
        Debug("&hostlist_hosts returning $MTT::Globals::Values->{hostlist}\n");
        return $MTT::Globals::Values->{hostlist};
    }
}

#--------------------------------------------------------------------------

# Return "1" if we have an "max_procs" setting in the globals in the
# INI file; "0" otherwise
sub have_ini_max_procs {
    Debug("&have_ini_max_procs\n");

    return (defined($MTT::Globals::Values->{max_np}) &&
            exists($MTT::Globals::Values->{max_np})) ? "1" : "0";
}

#--------------------------------------------------------------------------

# If we have a hostlist, return its max procs count
sub ini_max_procs {
    Debug("&ini_max_procs\n");

    return "0"
        if (!have_ini_max_procs());

    Debug("&ini_max_procs returning $MTT::Globals::Values->{max_np}\n");
    return $MTT::Globals::Values->{max_np};
}

#--------------------------------------------------------------------------

# Return "1" if we're running in a SLURM job; "0" otherwise.
sub slurm_job {
    Debug("&slurm_job\n");

    return ((exists($ENV{SLURM_JOBID}) &&
             exists($ENV{SLURM_TASKS_PER_NODE})) ? "1" : "0");
}

#--------------------------------------------------------------------------

# If in a SLURM job, return the max number of processes we can run.
# Otherwise, return 0.
sub slurm_max_procs {
    Debug("&slurm_max_procs\n");

    return "0"
        if (!slurm_job());

    # The SLURM env variable SLURM_TASKS_PER_NODE is a comma-delimited
    # list of strings.  Each string is of the form:
    # <tasks>[(x<nodes>)].  If the "(x<nodes>)" portion is not
    # specified, the <nodes> value is 1.

    my $max_procs = 0;
    my @tpn = split(/,/, $ENV{SLURM_TASKS_PER_NODE});
    my $tasks;
    my $nodes;
    foreach my $t (@tpn) {
        if ($t =~ m/(\d+)\(x(\d+)\)/) {
            $tasks = $1;
            $nodes = $2;
        } elsif ($t =~ m/(\d+)/) {
            $tasks = $1;
            $nodes = 1;
        } else {
            Warning("Unparsable SLURM_TASKS_PER_NODE: $ENV{SLURM_TASKS_PER_NODE}\n");
            return "0";
        }

        $max_procs += $tasks * $nodes;
    }

    Debug("&slurm_max_procs returning: $max_procs\n");
    return "$max_procs";
}

#--------------------------------------------------------------------------

# If in a SLURM job, return the hosts we can run on.  Otherwise,
# return "".
sub slurm_hosts {
    Debug("&slurm_hosts\n");

    return ""
        if (!slurm_job());

    # The SLURM env variable SLURM_NODELIST is a regexp of the hosts
    # we can run on.  Need to convert it to a comma-delimited list of
    # hosts; each host repeated as many times as dictated by the
    # corresponding entry in SLURM_TASKS_PER_NODE (see description of
    # SLURM_TASKS_PER_NODE in slurm_max_procs()).
    #
    # SLURM_NODELIST is a comma-delimited list of regular expressions.
    # Each entry will be of the form: base[ranges] (square brackets
    # are literal), where ranges is, itself, a comma-delimtied list of
    # ranges.  Each entry in ranges will be of the form: N[-M], where
    # N and M are integers, and the brackets are not literal (i.e.,
    # it'll be "N" or "N-M").

    # First, build a fully expanded list of task counts per node (see
    # slurm_max_procs() for a description of the format of
    # ENV{SLURM_TASKS_PER_NDOE}).

    my @tasks_per_node;
    my @tpn = split(/,/, $ENV{SLURM_TASKS_PER_NODE});
    foreach my $t (@tpn) {
        my $tasks;
        my $nodes;
        if ($t =~ m/(\d+)\(x(\d+)\)/) {
            $tasks = $1;
            $nodes = $2;
        } elsif ($t =~ m/(\d+)/) {
            $tasks = $1;
            $nodes = 1;
        } else {
            Warning("Unparsable SLURM_TASKS_PER_NODE: $ENV{SLURM_TASKS_PER_NODE}\n");
            return "";
        }

        while ($nodes > 0) {
            push(@tasks_per_node, $tasks);
            --$nodes;
        }
    }

    # Next, built a list of all nodes

    my @nodes;
    my $str = $ENV{SLURM_NODELIST};
    Debug("Parsing SLURM_NODELIST: $ENV{SLURM_NODELIST}\n");
    while ($str) {
        my $next_str;

        # See if we've got a "foo[ranges]" at the head of the string.
        # Be sure to be non-greedy in this regexp to grab only the
        # *first* part of the strgin!
        if ($str =~ m/^(.+?)\[([0-9\,\-]+?)\](.*)$/) {
            $next_str = $3;
            my $base = $1;
            Debug("Range: $1 - $2\n");
            # Parse the ranges
            my @ranges = split(/,/, $2);
            foreach my $r (@ranges) {
                if ($r =~ m/(\d+)-(\d+)/) {
                    # Got a start-finish range
                    my $str_len = length($1);
                    my $i = int($1);
                    my $end = int($2);
                    while ($i <= $end) {
                        my $num = $i;
                        $num = "0" . $num
                            while (length($num) < $str_len);
                        push(@nodes, "$base$num");
                        ++$i;
                    }
                } elsif ($r =~ m/^(\d+)$/) {
                    # Got a single number
                    push(@nodes, "$base$1");
                } else {
                    # Got an unexpected string
                    Warning("Unparsable SLURM_NODELIST: $ENV{SLURM_NODELIST}\n");
                    return "";
                }
            }
        } elsif ($str =~ m/^([^,]+)(.*)$/) {
            $next_str = $2;
            # No range; just a naked host -- save it and move on
            Debug("Naked host: ($str) $1\n");
            push(@nodes, $1);
        } else {
            Warning("Unparsable SLURM_NODELIST: $ENV{SLURM_NODELIST}\n");
            return "";
        }

        # Chop off the front of the string that we've already
        # processed and continue on.  Ensure that it starts with a ,
        # and then chop that off, too.
        $str = $next_str;
        Debug("Almost next: $str\n");
        if ($str && $str !~ s/^,(.+)/\1/) {
            Warning("Unparsable SLURM_NODELIST: $ENV{SLURM_NODELIST}\n");
            return "";
        }

        Debug("Next item: $str\n");
    }

    # Now combine the two lists -- they should be exactly the same
    # length.  Repeat each host as many times at it has tasks.

    my $ret;
    my $i = 0;
    while ($i <= $#tasks_per_node) {
        my $j = $tasks_per_node[$i];
        while ($j > 0) {
            $ret .= ","
                if ($ret);
            $ret .= $nodes[$i];
            --$j;
        }
        ++$i;
    }

    Debug("&slurm_max_procs returning: $ret\n");
    return $ret;
}

#--------------------------------------------------------------------------

# Return "1" if we're running in a PBS job; "0" otherwise.
sub pbs_job {
    Debug("&pbs_job\n");

    return ((exists($ENV{PBS_JOBID}) &&
             exists($ENV{PBS_ENVIRONMENT})) ? "1" : "0");
}

#--------------------------------------------------------------------------

# If in a PBS job, return the max number of processes we can run.
# Otherwise, return 0.
sub pbs_max_procs {
    Debug("&pbs_max_procs\n");

    return "0"
        if (!pbs_job());

    # Just count the number of lines in the $PBS_NODEFILE

    open (FILE, $ENV{PBS_NODEFILE}) || return "0";
    my $lines = 0;
    while (<FILE>) {
        ++$lines;
    }

    Debug("&pbs_max_procs returning: $lines\n");
    return "$lines";
}

#--------------------------------------------------------------------------

# If in a PBS job, return the hosts we can run on.  Otherwise, return
# "".
sub pbs_hosts {
    Debug("&pbs_hosts\n");

    return ""
        if (!pbs_job());

    # Return the uniq'ed contents of $PBS_HOSTFILE

    open (FILE, $ENV{PBS_NODEFILE}) || return "";
    my $lines;
    while (<FILE>) {
        chomp;
        $lines->{$_} = 1;
    }

    my @hosts = sort(keys(%$lines));
    my $hosts = join(",", @hosts);
    Debug("&pbs_hosts returning: $hosts\n");
    return "$hosts";
}

#--------------------------------------------------------------------------

# Return "1" if we're running in a N1GE job; "0" otherwise.
sub n1ge_job {
    Debug("&n1ge_job\n");

    return (exists($ENV{JOBID}) ? "1" : "0");
}

#--------------------------------------------------------------------------

# If in a N1GE job, return the max number of processes we can run.
# Otherwise, return 0.
sub n1ge_max_procs {
    Debug("&n1ge_max_procs\n");

    return "0"
        if (!n1ge_job());

    # Just count the number of lines in the $PE_HOSTFILE

    open (FILE, $ENV{PE_HOSTFILE}) || return "0";
    my $lines = 0;
    while (<FILE>) {
        ++$lines;
    }

    Debug("&n1ge_max_procs returning: $lines\n");
    return "$lines";
}

#--------------------------------------------------------------------------

# If in a N1GE job, return the hosts we can run on.
# Otherwise, return "".
sub n1ge_hosts {
    Debug("&n1ge_hosts\n");

    return ""
        if (!n1ge_job());

    # Return the uniq'ed contents of $PE_HOSTFILE

    open (FILE, $ENV{PE_HOSTFILE}) || return "";
    my $lines;
    while (<FILE>) {
        chomp;
        $lines->{$_} = 1;
    }

    my @hosts = sort(keys(%$lines));
    my $hosts = join(",", @hosts);
    Debug("&n1ge_hosts returning: $hosts\n");
    return "$hosts";
}

#--------------------------------------------------------------------------

# Return "1" if we're running in a Load Leveler job; "0" otherwise.
sub loadleveler_job {
    Debug("&loadleveler_job\n");

    return (exists($ENV{LOADLBATCH}) ? "1" : "0");
}

#--------------------------------------------------------------------------

# If in a Load Leveler job, return the max number of processes we can
# run.  Otherwise, return 0.
sub loadleveler_max_procs {
    Debug("&loadleveler_max_procs\n");

    return "0"
        if (!loadleveler_job());

    # Just count the number of tokens in $LOADL_PROCESSOR_LIST

    my $ret = 2;
    if (exists($ENV{LOADL_PROCESSOR_LIST}) && 
	$ENV{LOADL_PROCESSOR_LIST} ne "") {
      my @hosts = split(/ /, $ENV{LOADL_PROCESSOR_LIST});
      $ret = $#hosts + 1;
    }

    Debug("&loadleveler_max_procs returning: $ret\n");
    return $ret;
}


#--------------------------------------------------------------------------

# If in a Load Leveler job, return the hosts we can run on.
# Otherwise, return "".
sub loadleveler_hosts {
    Debug("&loadleveler_hosts\n");

    return ""
        if (!loadleveler_job());
    return ""
        if (!exists($ENV{LOADL_PROCESSOR_LIST}) ||
            "" eq $ENV{LOADL_PROCESSOR_LIST});

    # Just uniq the tokens in $LOADL_PROCESSOR_LIST

    my @tokens = split(/ /, $ENV{LOADL_PROCESSOR_LIST});
    my $tokens;
    foreach my $t (@tokens) {
        $tokens->{$t} = 1;
    }

    my @hosts = sort(keys(%$tokens));
    my $hosts = join(",", @hosts);
    Debug("&loadleveler_hosts returning: $hosts\n");
    return "$hosts";
}


#--------------------------------------------------------------------------

# Return the version of the GNU C compiler
sub get_gcc_version {
    Debug("&get_gcc_version\n");
    my $gcc = shift;
    my $ret = "unknown";

    $gcc = "gcc"
        if (!defined($gcc));
    if (open GCC, "$gcc --version|") {
        my $str = <GCC>;
        close(GCC);
        chomp($str);

        my @vals = split(" ", $str);
        $ret = $vals[2];
    }
    
    Debug("&get_gcc_version returning: $ret\n");
    return $ret;
}

#--------------------------------------------------------------------------

# Return the version of the Intel C compiler
sub get_icc_version {
    Debug("&get_icc_version\n");
    my $icc = shift;
    my $ret = "unknown";

    $icc = "icc"
        if (!defined($icc));
    if (open ICC, "$icc --version|") {
        my $str = <ICC>;
        close(ICC);
        chomp($str);

        my @vals = split(" ", $str);
        $ret = "$vals[2] $vals[3]";
    }
    
    Debug("&get_icc_version returning: $ret\n");
    return $ret;
}

#--------------------------------------------------------------------------

# Return the version of the PGI C compiler
sub get_pgcc_version {
    Debug("&get_pgcc_version\n");
    my $pgcc = shift;
    my $ret = "unknown";

    $pgcc = "pgcc"
        if (!defined($pgcc));
    if (open PGCC, "$pgcc -V|") {
        my $str = <PGCC>;
        $str = <PGCC>;
        close(PGCC);
        chomp($str);

        my @vals = split(" ", $str);
        $ret = "$vals[1] ($vals[2] $vals[5] $vals[6])";
    }
    
    Debug("&get_pgcc_version returning: $ret\n");
    return $ret;
}

#--------------------------------------------------------------------------

# Return the version of the Sun Studio C compiler
sub get_sun_cc_version {
    Debug("&get_sun_cc_version\n");
    my $cc = shift;
    $cc = "cc"
        if (!defined($cc));

    my $cc_v;
    my $version;
    my $date;

    $cc_v = `$cc -V 2>\&1 | head -1`;

    $cc_v =~ m/(\b5.\d+\b)/;
    $version = $1;

    $cc_v =~ m/(\d+\/\d+\/\d+)/;
    $date = $1;

    my $ret = "$version $date";

    Debug("&get_sun_cc_version returning: $ret\n");
    return $ret;
}

#--------------------------------------------------------------------------

# Return the version of the Pathscale C compiler
sub get_pathcc_version {
    Debug("&get_pathcc_version\n");
    my $pathcc = shift;
    my $ret = "unknown";

    $pathcc = "pathcc"
        if (!defined($pathcc));
    if (open PATHCC, "$pathcc -dumpversion|") {
        $ret = <PATHCC>;
        close(PATHCC);
        chomp($ret);
    }
    
    Debug("&get_pathcc_version returning: $ret\n");
    return $ret;
}

#--------------------------------------------------------------------------

# Detect the bitness of the MPI library in this order:
#   1) User overridden (CSV of 1 or more valid bitnesses)
#   2) Small test C program (using void*)
#   3) /usr/bin/file command output
#
# Return a database-ready bitmapped value
sub get_mpi_install_bitness {
    Debug("&get_mpi_intall_bitness\n");

    my $override    = shift;
    my $install_dir = $MTT::MPI::Install::install_dir;
    my $force       = 1;
    my $ret         = "0";

    # 1)
    # Users can override the automatic bitness detection
    # (useful in cases where the MPI has multiple bitnesses
    # e.g., Sun packages or Mac OSX universal binaries)
    if ($override) {
        $ret = _bitness_to_bitmapped($override);
        Debug("&get_mpi_install_bitness returning: $ret\n");
        return $ret;
    }

    # 2)
    # Write out a simple C program to output the bitness
    my $prog_name  = "get_bitness_c";
    my $executable = "$install_dir/$prog_name";
    my $mpicc      = "$install_dir/bin/mpicc";
    my $mpirun     = "$install_dir/bin/mpirun";

    # Make sure we have a valid mpicc and mpirun before attempting
    # this
    if (-x $mpicc && -x $mpirun) {
        my $x = MTT::Files::SafeWrite($force, "$executable.c", "/*
 * This program is automatically generated via the \"get_bitness\"
 * function of the MPI Testing Tool (MTT).  Any changes you make here may
 * get lost!
 *
 * Copyrights and licenses of this file are the same as for the MTT.
 */

#include <stdio.h>

int main(int argc, char* argv[]) {
    printf(\"%d\\n\", sizeof(void *) * 8);
    return 0;
}
");

        # Compile the program
        unlink($executable);
        $x = MTT::DoCommand::Cmd(1, "$mpicc $executable.c -o $executable");

        if (0 == $x->{exit_value} && -x $executable) {

            # It compiled ok, so now run it.  Use mpirun so that
            # various paths and whatnot are set properly.
            $x = MTT::DoCommand::Cmd(1, "$mpirun -np 1 $executable", 30);

            # Remove the get_bitness program and source
            unlink($executable);
            unlink("$executable.c");

            if (0 == $x->{exit_value}) {
                $ret = _extract_valid_bitness($x->{result_stdout});

                if (! $ret) {
                    Warning("&get_mpi_instaled_bitness(): Sample compiled program $prog_name did not execute properly.\n");
                    Warning("&get_mpi_instaled_bitness(): $prog_name output: " . $x->{result_stdout} . "\n");
                } else {
                    Debug("$prog_name executed properly.\n");
                    $ret = _bitness_to_bitmapped($ret);
                    Debug("&get_mpi_install_bitness returning: $ret\n");
                    return $ret;
                }
            } else {
                Warning("&get_mpi_install_bitness(): Couldn't execute sample compiled program: $prog_name.\n");
            }
        } else {
            Warning("&get_mpi_instaled_bitness(): Couldn't compile sample $prog_name.c.\n");
        }
    }

    # 3)
    # Try snarfing bitness using the /usr/bin/file command
    my $libmpi = _find_libmpi();
    if (! -f $libmpi) {
        Debug("Couldn't find libmpi!\n");
        return "0";
    }

    my $leader = "[^:]+:";
    my $bitnesses;

    # Split up file command's output
    my @file_out = split /\n/, `file $libmpi`;

    foreach my $line (@file_out) {

        # Mac OSX *implies* 32-bit for ppc and i386
        if ($line =~ /$leader.*\bmach-o\b.*\b(?:ppc|i386)\b/i) {
            $bitnesses->{32} = 1;

        # 64-bit
        } elsif ($line =~ /$leader.*\b64-bit\b/i) {
            $bitnesses->{64} = 1;

        # 32-bit
        } elsif ($line =~ /$leader.*\b32-bit\b/i) {
            $bitnesses->{32} = 1;
        }
    }

    # Compose CSV of bitness(es)
    my $str = join(',', keys %{$bitnesses});

    $ret = _extract_valid_bitness($str);

    if (! defined($ret)) {
        Warning("Could not get bitness using \"file\" command.\n");
    } else {
        Debug("Got bitness using \"file\" command.\n");
    }

    $ret = _bitness_to_bitmapped($ret);
    Debug("&get_mpi_install_bitness returning: $ret\n");
    return $ret;
}

# Make sure the bitness value makes sense
sub _extract_valid_bitness {

    my $str = shift;
    my $ret;

    Debug("Validating bitness string ($str)\n");

    # Valid bitnesses
    my $v = "8|16|32|64|128";

    # CSV of one or more bitnesses
    if ($str =~ /^((?:$v) (?:\s*,\s*(?:$v))*)$/x) {
        $ret = $1;
    } else {
        $ret = undef;
    }

    return $ret;
}

# Convert the human-readable CSV of bitness(es) to
# its representation in the MTT database.
sub _bitness_to_bitmapped {

    my $csv = shift;
    my $ret = 0;
    my $shift;

    Debug("Converting bitness string ($csv) to a bitmapped value\n");

    return $ret if (! $csv);

    my @bitnesses = split(/,/, $csv);

    # Smallest bitness possible
    my $smallest = 8;

    # Generate a bitmap of all bitnesses
    foreach my $bitness (@bitnesses) {
        $shift = log($bitness)/log(2) - log($smallest)/log(2);
        $ret |= (1 << $shift);
    }

    return $ret;
}

#--------------------------------------------------------------------------

# Return a database-ready bitmapped value for endian-ness
sub get_mpi_install_endian {
    Debug("&get_mpi_intall_endian\n");

    my $override = shift;
    my $ret      = "0";

    # 1)
    # Users can override the automatic endian detection
    # (useful in cases where the MPI has multiple endians
    # e.g., Mac OSX universal binaries)
    if ($override) {
        $ret = _endian_to_bitmapped($override);

        Debug("&get_mpi_install_endian returning: $ret\n");
        return $ret;
    }


    # 2)
    # Try snarfing endian(s) using the /usr/bin/file command
    my $libmpi          = _find_libmpi();
    if (! -f $libmpi) {
        # No need to Warning() -- the fact that the MPI failed to install
        # should be good enough...
        Debug("*** Could not find libmpi to calculate endian-ness\n");
        return "0";
    }

    my $leader          = "[^:]+:";
    my $hardware_little = 'i386|x86_64';
    my $hardware_big    = 'ppc|ppc64';
    my $endians;

    # Split up file command's output
    my @file_out = split /\n/, `file $libmpi`;

    foreach my $line (@file_out) {

        # Mac OSX
        if ($line =~ /$leader.*\bmach-o\b.*(?:$hardware_little)\b/i) {
            $endians->{little} = 1;

        # Mac OSX
        } elsif ($line =~ /$leader.*\bmach-o\b.*(?:$hardware_big)\b/i) {
            $endians->{big} = 1;

        # Look for 'MSB' (Most Significant Bit)
        } elsif ($line =~ /$leader.*\bMSB\b/i) {
            $endians->{big} = 1;

        # Look for 'LSB' (Least Significant Bit)
        } elsif ($line =~ /$leader.*\bLSB\b/i) {
            $endians->{little} = 1;
        }
    }

    # Compose CSV of endian(s)
    my $str = join(',', keys %{$endians});

    $ret = _endian_to_bitmapped($str);

    if (! $ret) {
        Debug("Could not get endian-ness from $libmpi using \"file\" command.\n");
    } else {
        Debug("Got endian-ness using \"file\" command on $libmpi.\n");
        return $ret;
    }

    # 3)
    # Auto-detect by casting an int to a char
    my $str = unpack('c2', pack('i', 1)) ? 'little' : 'big';
    $ret = _endian_to_bitmapped($str);

    Debug("&get_mpi_install_endianness returning: $ret\n");
    return $ret;
}

# Convert the human-readable CSV of endian(s) to
# its representation in the MTT database.
sub _endian_to_bitmapped {

    my $csv        = shift;
    my $ret        = 0;
    my $bit_little = 0;
    my $bit_big    = 1;

    Debug("Converting endian string ($csv) to a bitmapped value\n");

    return $ret if (! $csv);

    if ($csv =~ /little/i) {
        $ret |= $ret | (1 << $bit_little);
    }
    if ($csv =~ /big/i) {
        $ret |= $ret | (1 << $bit_big);
    }
    if ($csv =~ /both/i) {
        $ret |= $ret | (1 << $bit_little) | (1 << $bit_big);
    }

    Debug("&_endian_to_bitmapped returning: $ret\n");
    return $ret;
}

# Return the MPI library that will be passed to the file command
sub _find_libmpi {

    my $install_dir = $MTT::MPI::Install::install_dir;
    my $ret = undef;

    # Try to find a libmpi
    my @libmpis = (
        "$install_dir/lib/libmpi.dylib",
        "$install_dir/lib/libmpi.a",
        "$install_dir/lib/libmpi.so",
    );

    foreach my $libmpi (@libmpis) {
        if (-e $libmpi) {
            while (-l $libmpi) {
                $libmpi = readlink($libmpi);
                next if (-e $libmpi);
                $libmpi = "$install_dir/lib/$libmpi";
                next if (-e $libmpi);
                Warning("*** Got bogus sym link for libmpi -- points to nothing\n");
                return $ret;
            }

            $ret = $libmpi;
            last;
        }
    }

    Debug("&_find_libmpi returning: $ret\n");
    return $ret;
}

#--------------------------------------------------------------------------

sub weekday_name {
    my @days = qw/sun mon tue wed thu fri sat/;
    Debug("&weekday_name returning: " . $days[weekday_index()] . "\n");
    return $days[weekday_index()];
}

# 0 = Sunday;
sub weekday_index {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
        localtime(time);
    Debug("&weekday_index returning: $wday\n");
    return $wday;
}

#--------------------------------------------------------------------------

sub getenv {
    my $name = shift(@_);
    Debug("&getenv($name) returning: $ENV{$name}\n");
    return $ENV{$name};
}

#--------------------------------------------------------------------------

sub scratch_root {
    Debug("&scratch_root() returning: $MTT::Globals::Values->{scratch_root}\n");
    return $MTT::Globals::Values->{scratch_root};
}

#--------------------------------------------------------------------------

# Return something that will be snipped out of the final evaluation
sub null {
    Debug("&null returning: undef\n");
    return undef;
}

#--------------------------------------------------------------------------

sub mpi_get_name {
    Debug("&mpi_get_name returning: $MTT::Globals::Internals->{mpi_get_name}\n");
    return $MTT::Globals::Internals->{mpi_get_name};
}

sub _get_hash_keys {
    my ($pattern, $hash) = @_;

    my @ret;
    
    # Match everything if no pattern is supplied
    if (! defined($pattern)) {
        return keys %$hash;
    }

    my @ret;
    foreach my $key (keys %$hash) {
        if ($key =~ /$pattern/i) {
            push(@ret, $key);
        }
    }

    Debug("&_get_hash_keys returning: @ret\n");
    return \@ret;
}

# The below get INI section name command are especially useful in the case
# where a user is not concerned about multiplying "MPI Installs" times "MPI
# gets". In other words, it allows one to simplify this command:
#
#   $ client/mtt --section "install-foo" mpi_get=install-foo
# 
# Instead, leave out the mpi_get command-line override, and set 
# mpi_get like this in the INI:
#
#   mpi_get = &get_any_mpi_get_name()
#

sub get_mpi_get_names {
    my ($pattern) = @_;
    my @arr = _get_hash_keys($pattern, $MTT::MPI::sources);
    @arr = delete_duplicates_from_array(@arr);
    return join(",", @arr);
}

sub get_mpi_install_names {
    my ($pattern) = @_;

    my @arr;
    foreach my $mpi_get_key (keys %$MTT::MPI::installs) {

        my $mpi_get = $MTT::MPI::sources->{$mpi_get_key};
        foreach my $version_key (keys %{$mpi_get}) {
            push(@arr, _get_hash_keys($pattern, $mpi_get->{$version_key}));
        }
    }

    @arr = delete_duplicates_from_array(@arr);
    my $ret = join(",", @arr);
    return $ret;
}

sub get_test_get_names {
    my ($pattern) = @_;
    return _get_hash_keys($pattern, $MTT::Test::sources);
}

sub get_test_build_names {
    my ($pattern) = @_;

    my @arr;
    foreach my $mpi_get_key (keys %$MTT::Test::builds) {

        my $mpi_get = $MTT::MPI::sources->{$mpi_get_key};
        foreach my $mpi_get_key (keys %{$mpi_get}) {

            my $version = %{$mpi_get};
            foreach my $version_key (keys %{$version}) {

                my $mpi_install = $mpi_get->{$version_key};
                foreach my $build_key (keys %{$mpi_install}) {
                    push(@arr, _get_hash_keys($pattern, $mpi_install->{$build_key}));
                }
            }
        }
    }

    @arr = delete_duplicates_from_array(@arr);
    my $ret = join(",", @arr);
    return $ret;
}

sub get_test_run_names {
    my ($pattern) = @_;

    my @arr;
    foreach my $mpi_get_key (keys %$MTT::Test::builds) {

        my $mpi_get = $MTT::MPI::sources->{$mpi_get_key};
        foreach my $mpi_get_key (keys %{$mpi_get}) {

            my $version = %{$mpi_get};
            foreach my $version_key (keys %{$version}) {

                my $mpi_install = $mpi_get->{$version_key};
                foreach my $build_key (keys %{$mpi_install}) {

                    my $test_build = $mpi_get->{$version_key};
                    foreach my $build_key (keys %{$test_build}) {
                        push(@arr, _get_hash_keys($pattern, $test_build->{$build_key}));
                    }
                }
            }
        }
    }

    @arr = delete_duplicates_from_array(@arr);
    my $ret = join(",", @arr);
    return $ret;
}

#--------------------------------------------------------------------------

sub mpi_install_name {
    Debug("&mpi_install_name returning: $MTT::Globals::Internals->{mpi_install_name}\n");
    return $MTT::Globals::Internals->{mpi_install_name};
}

#--------------------------------------------------------------------------

sub test_get_name {
    Debug("&test_get_name returning: $MTT::Globals::Internals->{test_get_name}\n");
    return $MTT::Globals::Internals->{test_get_name};
}

#--------------------------------------------------------------------------

sub test_build_name {
    Debug("&test_build_name returning: $MTT::Globals::Internals->{test_build_name}\n");
    return $MTT::Globals::Internals->{test_build_name};
}

#--------------------------------------------------------------------------

sub test_run_name {
    Debug("&test_run_name returning: $MTT::Globals::Internals->{test_run_name}\n");
    return $MTT::Globals::Internals->{test_run_name};
}

#--------------------------------------------------------------------------

sub mpi_details_name {
    Debug("&mpi_details_name returning: $MTT::Globals::Internals->{mpi_details_name}\n");
    return $MTT::Globals::Internals->{mpi_details_name};
}

sub mpi_details_simple_name {
    Debug("&mpi_details_simple_name returning: $MTT::Globals::Internals->{mpi_details_simple_name}\n");
    return $MTT::Globals::Internals->{mpi_details_simple_name};
}

#--------------------------------------------------------------------------
#--------------------------------------------------------------------------
#--------------------------------------------------------------------------

sub _get_array_ref {
    # We got a reference as an argument which will be a reference to
    # one of three things:
    # - a reference to an array of strings
    # - an array of strings
    # - a single string (which is really the same thing as an array of
    #   strings)

    # If the first element of the array is a reference to an array,
    # then return the dereference (so we get just a single reference
    # to an array [vs. a reference to a reference to an array])
    my $array = shift;
    my $elem = @$array[0];
    my $r = ref($elem);
    if ("" eq $r) {
        # The first element wasn't a reference, so just return the
        # outter reference
        Debug("Returining outter reference\n");
        return $array;
    } elsif ($r =~ /array/i) {
        # The first element was a reference, so return the
        # "dereference" of it
        Debug("Returning de-ref'ed array\n");
        return $elem;
    } else {
        # If we got some other type of reference, we don't like it.
        Warning("Funclet got unknown parameter reference type -- ignored\n");
        return undef;
    }
}

sub current_phase {
    return $MTT::Globals::Values->{active_phase};
}

sub current_section {
    return $MTT::Globals::Values->{active_section};
}

sub current_simple_section {
    return GetSimpleSection($MTT::Globals::Values->{active_section});
}

1;
