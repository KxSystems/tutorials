STDOUT:-1
$[@[{x in key .comkxic.libs}; `qlog; 0b]; [
  id:.com_kx_log.init[`:fd://stdout; ()];
  .qlog: .com_kx_log.new[`nano; ()]]; [
  .qlog.debug: {[m:`C] STDOUT ssr[-6_5_string .z.p; "D"; " "], " ", m;};
  .qlog.info:  {[m:`C] STDOUT ssr[-6_5_string .z.p; "D"; " "], " ", m;};
  .qlog.warn:  {[m:`C] STDOUT ssr[-6_5_string .z.p; "D"; " "], " ", "\033[43;37m", m ,"\033[0m";};
  .qlog.error: {[m:`C] STDOUT ssr[-6_5_string .z.p; "D"; " "], " ", "\033[41;37m", m ,"\033[0m";}]];
