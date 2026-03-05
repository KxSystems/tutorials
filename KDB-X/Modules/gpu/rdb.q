// Simulate an rdb usecase by accumulating chunks of quote & handling trade aj requests as they arrive

batchSize:100000     // Size batches to take from q & t (ms)
// logBatches:1000000  // Log progress after this many batches
logBatches:10000
nBatches:0          // How many batches to process (zero for all)
// nBatches:650000
nBatches:20000

system $[()~key`:shorthand.q;"l ../../shorthand.q";"l shorthand.q"];
.gpu.sdev 2

start "----- Build batches in memory"
start "Load data"
system $[()~key`:data;"l examples/aj/data/HDB/tq/zd0_0_0";"l data/HDB/tq/zd0_0_0"];
tall:select from trade
qall:select from quote
trade:0; quote:0;
end`

start "Sort data by time"
`Time xasc `tall;
`Time xasc `qall;
end`

ms:1000000
start "Chunk by ",string[batchSize],"ms"
txb:select qidx:(), tidx:i by bucket:batchSize*ms xbar Time from tall
qxb:select qidx:i, tidx:() by bucket:batchSize*ms xbar Time from qall
end`

start "Build batch table"
batches: `bucket xasc 0!txb,qxb
if[0~nBatches;nBatches:count batches]
end`
end`;-1""; / "----- Build batches in memory"

processBatch:{[lbl;appendfn;ajfn;bidx]
    batch:batches bidx;
    str:"batch ",string[bidx],": ";
    if[0<>c:count qidx:batch`qidx; start str,"append ",string[c]," quotes";appendfn qall qidx;end`];
    if[0<>c:count tidx:batch`tidx; start str,"aj ",string[c]," trades, ",string[count q]," quotes";ajfn[`Symbol`Time;tall tidx;q];end`];
    if[0~bidx mod logBatches;-1"Completed ",lbl," batch ",string bidx];
    }

// Simple CPU processing (time gets excessive if no `g on Symbol)
processBatchCPU:processBatch["cpu";{q,::x};aj]

// Simple cpu processing, using upsert instead of append
// processBatchCPU:processBatch["cpu";{`q upsert x};aj]

// Init quote schema
q:0#qall;
// update `p#Symbol from `q
update `g#Symbol from `q

start "cpu process batches with `g#Symbol"
printse:0b;
processBatchCPU each til nBatches; //! KIT-72: option to run in real time? timer?
printse:1b;
end`;

// Simple GPU (with copying)
// processBatchGPU:processBatch["gpu";{q,::x};.gpu.aj]

// always .gpu.append (very slow for small batches)
processBatchGPU:processBatch["gpu";{q::.gpu.append[q;x]};.gpu.aj]

//! KIT-72: hybrid approach batching on cpu before gpu transfers

// Init quote schema
//! KIT-72: need a single row for now to support .gpu.append
q:1#qall;
q:xto[`Time`Symbol] q
// No attrib for gpu, could be nice to use one to mandate a column exist on gpu

start "gpu process batches"
printse:0b;
processBatchGPU each 1_til nBatches; //! KIT-72: option to run in real time? timer?
printse:1b;
end`;

exit 0
