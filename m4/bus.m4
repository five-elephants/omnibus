dnl Copyright 2015 Heidelberg University Copyright and related rights are
dnl licensed under the Solderpad Hardware License, Version 0.51 (the "License");
dnl you may not use this file except in compliance with the License. You may obtain
dnl a copy of the License at http://solderpad.org/licenses/SHL-0.51. Unless
dnl required by applicable law or agreed to in writing, software, hardware and
dnl materials distributed under this License is distributed on an "AS IS" BASIS,
dnl WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See
dnl the License for the specific language governing permissions and limitations
dnl under the License.

divert(-1)

dnl define(`LQ', `changequote(<,>)`dnl'
dnl changequote`'')
dnl define(`RQ', `changequote(<,>)dnl`
dnl 'changequote`'')

changequote(<:,:>)

define(<:bus_begin:>, <:dnl
divert(-1)dnl
  pushdef(<:busprefix:>, <:$1:>)dnl
  define(<:busclk:>, <:$2:>)dnl
  define(<:out_n:>, <:-1:>)dnl
  define(<:node_n:>, <:-1:>)dnl
  define(<:interfaceparam:>, ifelse($3, <::>, <::>, <: <:<:#:>($3):>:>))dnl

  define(<:master:>, <:pushdef(<:busout:>, :>$<::>1<:):>)
  define(<:slave:>, <:define(busprefix()_slave_:>$<::>1<:, busout)popdef(<:busout:>):>)
  define(<:terminator:>, <:define(<:node_n:>, incr(node_n))dnl

    Bus_slave_terminator busprefix()_t<::>node_n() (busout);popdef(<:busout:>)dnl:>)

  dnl define(<:with_byteen:>. <:.byteen(1):>)
  define(<:num_in_flight:>, <:.NUM_IN_FLIGHT(:>$<::>1<:):>)
  define(<:reset_by_0:>, <:.RESET_BY_0(:>$<::>1<:):>)
  define(<:reset_by_1:>, <:.RESET_BY_1(:>$<::>1<:):>)

  define(<:arb:>, <:define(<:node_n:>, incr(node_n))dnl

    Bus_if<::>interfaceparam() busprefix()_out_<::>incr(out_n) (.Clk(busclk));
    Bus_if_arb ifelse(:> $<::>1 <:,<::>, <::>, <:<:#:>(:>:> $<::>1 <:<:):>) busprefix()_a<::>node_n() (
      .in_1(busout)popdef(<:busout:>),
      .in_0(busout)popdef(<:busout:>), define(<:out_n:>, incr(out_n)) pushdef(<:busout:>, <:busprefix()_out_<::>out_n():>)
      .out(busout)
    );
  :>)

  define(<:delay:>, <:define(<:node_n:>, incr(node_n))dnl

    Bus_if<::>interfaceparam() busprefix()_out_<::>incr(out_n) (.Clk(busclk));
    Bus_delay busprefix()_d<::>node_n() (
      .in(busout),popdef(<:busout:>)define(<:out_n:>, incr(out_n)) pushdef(<:busout:>, <:busprefix()_out_<::>out_n():>)
      .out(busout)
    );
  :>)

  define(<:split:>, <:define(<:node_n:>, incr(node_n))

    Bus_if<::>interfaceparam() busprefix()_out_<::>incr(out_n) (.Clk(busclk));
    Bus_if<::>interfaceparam() busprefix()_out_<::>incr(incr(out_n)) (.Clk(busclk));
    Bus_if_split <:#:>(.SELECT_BIT(:>$<::>1 <:)ifelse(:>$<::>2<:, <::>, <::>, <:,:>:>$<::>2<:)) busprefix()_s<::>node_n() (
      .top(busout),popdef(<:busout:>)define(<:out_n:>, incr(out_n))pushdef(<:busout:>, busprefix()_out_<::>out_n())
      .out_1(busout),define(<:out_n:>, incr(out_n)) pushdef(<:busout:>, busprefix()_out_<::>out_n())
      .out_0(busout)
    );
  :>)
divert(0)dnl
    // begin bus $1 dnl
:>)

define(<:bus_end:>, <:
    // end bus busprefix popdef(<:busprefix:>)
undefine(<:master:>)dnl
undefine(<:slave:>)dnl
undefine(<:terminator:>)dnl
undefine(<:delay:>)dnl
undefine(<:split:>)dnl
undefine(<:arb:>)dnl
undefine(<:num_in_flight:>)dnl
undefine(<:node_n:>)dnl
undefine(<:out_n:>)dnl
undefine(<:busclk:>)dnl
undefine(<:interfaceparam:>)dnl
:>)


divert(0)dnl
dnl
dnl bus_begin(test, clk)
dnl   master(one)
dnl   master(two) arb
dnl     master(three) arb(num_in_flight(16))
dnl       delay
dnl       split(31, num_in_flight(8)) slave(a)
dnl         split(30) slave(b) slave(c)
dnl bus_end()
dnl 
dnl my_module(
dnl   .slave_a(test_slave_a),
dnl   .slave_b(test_slave_b),
dnl   .slave_c(test_slave_c)
dnl );
dnl 
