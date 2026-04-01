// Improvement of tq.q available at https://github.com/KxSystems/kdb-taq
// Improvements include:
//    * k code is rewritten to q
//    * destination directory is not hardcoded
//    * new parameter to filter on the first letter of the Symbol
//    * improved error handling
//    * code quality improvements


STDOUT:-1
$[@[{x in key .comkxic.libs}; `qlog; 0b]; [
  id:.com_kx_log.init[`:fd://stdout; ()];
  .qlog: .com_kx_log.new[`nano; ()]]; [
  .qlog.debug: {[m:`C] STDOUT ssr[-6_5_string .z.p; "D"; " "], " ", m;};
  .qlog.info:  {[m:`C] STDOUT ssr[-6_5_string .z.p; "D"; " "], " ", m;};
  .qlog.warn:  {[m:`C] STDOUT ssr[-6_5_string .z.p; "D"; " "], " ", "\033[43;37m", m ,"\033[0m";};
  .qlog.error: {[m:`C] STDOUT ssr[-6_5_string .z.p; "D"; " "], " ", "\033[41;37m", m ,"\033[0m";}]];

if[(5.0>.z.K); .qlog.error "KDB-X (kdb+ 5.0) is required";exit 1];
ko:key o:first each .Q.opt .z.x
if[not all `src`dst in ko; 
  .qlog.error ">q ",(string .z.f)," -src SRC -dst DST [-letter START-END]";exit 2];
letterConv: $[`letter in ko; [
  LETTER:o`letter;
  if[not LETTER like "?..?";
    .qlog.error "letter must be in form START..END, for example A..K";
    exit 2];
  {select from y where (first each Symbol) within x}[LETTER except "."]]; ::];

SRC:hsym `$o`src
DST:hsym `$o`dst

symbolConv: {update`$Symbol from update "."^Symbol from x where Symbol like"* *"}

psym: {[c:`s; x:`s]
  if[null @[@[;c;`p#];x;`];
    broken:x where not(x?x)=til count x@:where not=':[x@:c];
    .qlog.error "parted attribute cannot be applied on ", string[c], " due to ", "," sv string broken]
  }

getPart: {[dir:`s;tableName:`s;fileName:`s]
  .Q.par[dir;"D"$-8#string fileName;tableName]
  }

process: {[tableName:`s;colNames:`S;colTypes;conv;op;fileName:`s]
  p: .Q.dd[getPart[DST;tableName;fileName];`];
  fullFileName: .Q.dd[SRC;fileName];
  .qlog.info "Processing file ", 1_string fullFileName;
  / load and drop last line
  raw: -1 _ colTypes 0:fullFileName;
  / rename, convert and enumerate
  t: .Q.en[DST] conv flip colNames!value flip raw;
  / save
  .[p;();op;t];
  }

th:`Time`Exchange`Symbol`SaleCondition`TradeVolume`TradePrice`TradeStopStockIndicator,
  `TradeCorrectionIndicator`SequenceNumber`TradeId`SourceofTrade`TradeReportingFacility,
  `ParticipantTimestamp`TradeReportingFacilityTRFTimestamp`TradeThroughExemptIndicator;
tf:("NC*SIEBHI*CBNNB";enlist"|")

qh:`Time`Exchange`Symbol`Bid_Price`Bid_Size`Offer_Price`Offer_Size`Quote_Condition,
  `Sequence_Number`National_BBO_Ind`FINRA_BBO_Indicator`FINRA_ADF_MPID_Indicator,
  `Quote_Cancel_Correction`Source_Of_Quote`Retail_Interest_Indicator,
  `Short_Sale_Restriction_Indicator`LULD_BBO_Indicator`SIP_Generated_Message_Identifier,
  `National_BBO_LULD_Indicator`Participant_Timestamp`FINRA_ADF_Timestamp,
  `FINRA_ADF_Market_Participant_Quote_Indicator`Security_Status_Indicator
qf:("NC*FIFICICCCCCCCCCCNNCC";enlist"|")
conv: symbolConv letterConv@

Q: asc F where (lower F:key SRC) like "splits_us_all_bbo_*[0-9]"
if[0<count Q;
  .qlog.info "Processing quote tables...";
  process[`quote;qh;qf;conv;:] first Q;
  process[`quote;qh;qf;conv;,] each 1_Q;
  .qlog.info "Adding parted attribute...";
  psym[`Symbol] each distinct getPart[DST;`quote] each Q]

T: F where lower[F] like "eqy_us_all_trade_[0-9]*"
.qlog.info "Processing trade tables..."
process[`trade;th;tf;conv;:] each T
.qlog.info "Adding parted attribute..."
psym[`Symbol] each distinct getPart[DST;`trade] each T

if[not `debug in ko; exit 0]
