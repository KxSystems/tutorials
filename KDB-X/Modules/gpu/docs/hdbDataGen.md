# NYSE data generation from https://github.com/KxSystems/compression-test-taq

Only a few days of data is available at the NYSE TAQ site. This data is replaced by newer data on a regular basis. The `genHDB.sh` script:

   1. Downloads compressed CSVs using `wget -c`. Flag `-c` is used to resume downloading if internet connection breaks.
   1. Extracts files
   1. Generates HDB using modified KX TAQ scripts `src/tq.q`

The compression benefit depends on the disk speed. Build the HDB on a storage that you would like to test. The path of the HDB directory can be passed as the first parameter of `genHDB.sh`.

```bash
export SIZE=medium
export QEXEC=`which q`
export DATE=$(curl -s https://ftp.nyse.com/Historical%20Data%20Samples/DAILY%20TAQ/| grep -oE 'EQY_US_ALL_TRADE_2[0-9]{7}' | grep -oE '2[0-9]{7}'|head -1)
bash genHDB.sh ./HDB $DATE
```

### Data size

A single day of NYSE TAQ files contain large amount of data. You can speed up the test if only a part of the BBO split CSV files (source of table `quote`) are considered. Set the `SIZE` environment variable to balance between test execution time and test accuracy. Except for the `full` mode only a subset of the BBO split CSV files are downloaded and only the corresponding trades will be converted into HDB (e.g. only symbols with Z as the first letter).

Some statistics of various DB sizes with data from 2025.01.02 are below

| `SIZE` | Symbol first letters | HDB size (GB) | Nr of quote Symbols | Nr of quotes | 
| --- | --- | ---: | ---: | ---: |
| `small` | Z | 1 | 94 | 4 607 158 |
| `medium` | I | 13 | 555 | 180 827 332 |
| `large` | A-H| 52 | 4849 | 707 738 295 |
| `full` | A-Z | 233 | 11155 | 2 313 872 956 |
