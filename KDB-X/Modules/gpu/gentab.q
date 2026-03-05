// This file generates dummy data for sorting

orders:flip (!) . flip (
	(`orderId; 		`int$());
	(`productId;		`int$());
	(`time;		`long$());
	(`pubTime;		`long$());
	(`accId;		`short$());
	(`analyticId;		`short$());
	(`analyticDataType;	`char$());
	(`doubleValue;		`float$());
	(`stringValue;		`symbol$());
	(`processPre;	());
	(`processSuf;	());
	(`orderKey;		`guid$())
 );

/ data template
dt:()!()
dt[`orderId]:`int$1000 + 9000?9000;
dt[`productId]:`int$1000000+1000+9000?9000;
dt[`time]:enlist 1769423038687723902;
dt[`pubTime]:enlist 1769423038687723902;
dt[`accId]:55761 57576 75578;
dt[`analyticId]:162 201;
dt[`analyticDataType]:"DF";
/ no double val
dt[`stringValue]:`FNGS`VOD`BARC`GOOG`AAPL;
dt[`processPre]:2#enlist "ABC_123VRYAN3B";
dt[`processSuf]:2#enlist "422VRYAN3B";
dt[`orderKey]:2?0Ng;

datagen:(!) . flip (
       (`orderId;              {x?dt[`orderId]});
       (`productId;            {x?dt[`productId]});
       (`time;            {dt[`time][0]+til x});
       (`pubTime;          {dt[`pubTime][0]+til x});
       (`accId;            {x?dt[`accId]});
       (`analyticId;           {x?dt[`analyticId]});
       (`analyticDataType;     {x?dt[`analyticDataType]});
       (`doubleValue;          {x?10});
       (`stringValue;          {string x?dt[`stringValue]});
       (`processPre;        {x?dt[`processPre]});
       (`processSuf;        {x?dt[`processSuf]});
       (`orderKey;             {x?dt[`orderKey]})
 );

/ dir: Directory to save in and 
/ n:   Number for records
/ gentab[dbpath;100]
gentab:{[dir;n]
 columns:cols orders;
 -1 "Writing .d file";
 .[` sv dir,`.d;();:;columns];
 {[d;n;c]
      fp:` sv d,c;
      -1 "Writing col ",string[c]," to ",string fp;
      fp set datagen[c][n]
      }[dir;n;] each columns;
 };

gentabchunked:{[dbtab;n; batchSize]
      {
       -1 "Writing batch ",string[x]," of size ",string[y]," to ",string z;
       z upsert flip c!(datagen each c:cols orders)@\:y;
      }[;batchSize;dbtab] each til n div batchSize
      }


