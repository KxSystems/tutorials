// This file generates dummy data for sorting

orders:([] orderId: `int$();
          productId:`int$();
          time: `long$();
          pubTime: `long$();
          accId: `short$();
          analyticId: `short$();
          analyticDataType: `char$();
          doubleValue: `float$();
          stringValue: `symbol$();
          processPre: ();
          processSuf: ();
          orderKey: `guid$()
      );

/ data template
dt:([
      orderId: `int$1000 + 9000?9000;
      productId:`int$1000000+1000+9000?9000;
      time:enlist 1769423038687723902;
      pubTime:enlist 1769423038687723902;
      accId:55761 57576 75578;
      analyticId:162 201;
      analyticDataType:"DF";
      / no double val
      stringValue:`FNGS`VOD`BARC`GOOG`AAPL;
      processPre:2#enlist "ABC_123VRYAN3B";
      processSuf:2#enlist "422VRYAN3B";
      orderKey:2?0Ng
      ]);

datagen:([
      orderId: {x?dt[`orderId]};
      productId: {x?dt[`productId]};
      time: {dt[`time][0]+til x};
      pubTime:{dt[`pubTime][0]+til x};
      accId: {x?dt[`accId]};
      analyticId: {x?dt[`analyticId]};
      analyticDataType: {x?dt[`analyticDataType]};
      doubleValue: {x?10};
      stringValue: {string x?dt[`stringValue]};
      processPre: {x?dt[`processPre]};
      processSuf: {x?dt[`processSuf]};
      orderKey: {x?dt[`orderKey]}
      ]);

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

