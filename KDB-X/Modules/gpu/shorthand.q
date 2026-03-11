// Shorthand utility functions for GPU tutorials

\c 5000 5000

.gpu:use`gpu
(to;xto;fr;dbg;hex;zero):.gpu`to`xto`from`dbg`hex`zero;

started:0#() // Stack of started nvtx ranges (section name; id; start time)
ended:0#()   // List of ended nvtx ranges (section name;start time;time taken)
printse:1b;
start:{[sec] if[printse;-1"[",string[st:.z.t],"] start: ",sec];id:.gpu.nvtx.start sec;started,::enlist (sec;id;st);};
end:{ls:last started;.gpu.nvtx.end ls 1;if[printse;-1"[",string[.z.t],"] end: ",ls[0]," (took ",string[t:.z.t-ls[2]],")"];started::-1_started;ended,::enlist(ls 0;ls 2;t);};
