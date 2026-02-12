# Using SQL in KDB-X

SQL provides a familiar relational interface for querying and managing data in KDB-X, allowing users to leverage standard SQL syntax within the q environment.
This tutorial will walk through some examples of how to use SQL to interact with and manipulate q objects, and then show how to utilise the power of q functionality through SQL.

*Note: SQL is currently supplied embedded in the q executable but may be be provided as a module in the future..*

## 1. Prerequisites

View the [KDB-X Docs](https://code.kx.com/kdb-x/index.html) for full details on KDB-X and KDB-X Python.

1. Requires KDB-X to be installed, you can sign up [here](https://developer.kx.com/products/kdb-x/install). For full install instructions see: [KDB-X Install](https://code.kx.com/kdb-x/get_started/kdb-x-install.html).
2. Ensure you have the necessary dataset

## 2. Loading and Preparing the Data

Launch a q session by running `q`:
```
Welcome to KDB-X Community Edition!
For Community support, please visit https://kx.com/slack
Tutorials can be found at https://github.com/KxSystems/tutorials
Ready to go beyond the Community Edition? Email preview@kx.com
q)
```
Load the dataset into a q table:
```q
//Run the initialisation function so that you can use s) or .s.e straight away
.s.init[]
// The \z system command sets the format for date parsing 
\z 1

fvprices:("SSSDSF"; enlist ",") 0: `$":/src/wholesaleproduceprices.csv"
```
In the above:
- `0:` is used to read the csv file
- The schema `"SSSDSF"` specifies the datatypes for each column
- The `","` ensures the CSV is parsed using commas as delimiters.

Now the dataset has been loaded, we can inspect the table using first to see what the first row of the table looks like:
```q
first fvprices;
```
```
category| `fruit
item    | `apples
variety | `bramleys_seedling
date    | 2025.10.13
unit    | `kg
price   | 1.27
```

The table above is a simple table giving information on average wholesale prices of selected home-grown horticultural produce in England and Wales. It is updated every fortnight.
Source: https://www.gov.uk/government/statistical-data-sets/wholesale-fruit-and-vegetable-prices-weekly-average.

## 3. Use SQL to interrogate a q table

In this tutorial, we are going to query the above dataset using both q and SQL.  
This is particularly useful if you have a q object that you need to interrogate, but your skillset is more suited to SQL than the q language.

### 3.1 Common query types in SQL 

There are a few different ways to query using SQL within a q session.

The first option is to use `s)` and then standard SQL code. To return all rows of the table:
```SQL
s)SELECT * FROM fvprices
```
```
category  item                 variety                date       unit price
---------------------------------------------------------------------------
fruit     apples               bramleys_seedling      2025.10.13 kg   1.27
fruit     apples               coxs_orange_group      2025.10.13 kg   1.22
fruit     apples               egremont_russet        2025.10.13 kg   1.46
fruit     apples               braeburn               2025.10.13 kg   1.38
fruit     apples               gala                   2025.10.13 kg   1.23
fruit     blackberries         blackberries           2025.10.13 kg   15.35
fruit     blueberries          blueberries            2025.10.13 kg   12.19
fruit     pears                conference             2025.10.13 kg   1.22
fruit     pears                doyenne_du_comice      2025.10.13 kg   1.17
fruit     plums                all_other              2025.10.13 kg   1.52
fruit     raspberries          raspberries            2025.10.13 kg   13.16
fruit     strawberries         strawberries           2025.10.13 kg   4.08
vegetable beans                dwarf_french_or_kidney 2025.10.13 kg   1.87
vegetable beans                runner_climbing        2025.10.13 kg   3.92
vegetable beetroot             beetroot               2025.10.13 kg   0.7
vegetable brussels_sprouts     brussels_sprouts       2025.10.13 kg   1
..
```

However, you don’t have to capitalise key words like SELECT and FROM:
```SQL
s)select * from fvprices where category = 'vegetable' 
```
```
category  item                 variety                date       unit price
---------------------------------------------------------------------------
vegetable beans                dwarf_french_or_kidney 2025.10.13 kg   1.87
vegetable beans                runner_climbing        2025.10.13 kg   3.92
vegetable beetroot             beetroot               2025.10.13 kg   0.7
vegetable brussels_sprouts     brussels_sprouts       2025.10.13 kg   1
vegetable pak_choi             pak_choi               2025.10.13 kg   3.5
vegetable curly_kale           curly_kale             2025.10.13 kg   4.19
vegetable cabbage              red                    2025.10.13 kg   0.54
vegetable cabbage              savoy                  2025.10.13 head 0.64
vegetable spring_greens        prepacked              2025.10.13 kg   1.39
vegetable cabbage              summer_autumn_pointed  2025.10.13 kg   0.79
vegetable cabbage              white                  2025.10.13 kg   0.52
vegetable cabbage              round_green_other      2025.10.13 head 0.62
..
```

Another way to query using SQL is to wrap your SQL code within quotation marks using `.s.e`:

```SQL
.s.e"SELECT category, COUNT(item) AS count_per_category FROM fvprices GROUP BY category"
```
```
category    count_per_category
------------------------------
cut_flowers 423
fruit       3521
pot_plants  49
vegetable   12673
```

Common SQL aggregations and calculations are supported in KDB-X. For example, to find the avg price of each type of item:
```SQL
.s.e"SELECT category,item,unit,avg(price) AS avg_price FROM fvprices GROUP BY category,item ORDER BY avg_price DESC"
```
```
category    item                 unit avg_price
-----------------------------------------------
vegetable   asparagus            kg   10.35726
vegetable   watercress           kg   9.374348
fruit       raspberries          kg   8.969415
fruit       blueberries          kg   8.801304
fruit       blackberries         kg   8.368394
fruit       currants             kg   8.165982
fruit       gooseberries         kg   6.566883
fruit       cherries             kg   5.314222
vegetable   rocket               kg   5.295729
vegetable   mixed_babyleaf_salad kg   5.292558
..
```

### 3.2 Defining functions

Functions can be used in a number of different ways using both SQL and q. 

You can define a function to return a table in SQL and then query the result of that function:
```q
x:.s.e"SELECT item, variety, unit, avg(price) as avg_price FROM fvprices WHERE price>15.00 GROUP BY variety";

.s.e"select item, avg_price from x";
```
```
item         avg_price
----------------------
cherries     16.08
asparagus    17.20381
currants     17.16
blackberries 16.342
gooseberries 16.7075
raspberries  16.57
currants     15.82
```
### 3.3 Using parameters
To parameterize your function, you can use `.s.sp`. The function expects a list of parameters so in the case where you only need one parameter, you can use `enlist`.
```SQL
.s.sp["select item,variety, price from fvprices where category=$1"](enlist `fruit);
```
```
item         variety            price
-------------------------------------
apples       bramleys_seedling  1.27
apples       coxs_orange_group  1.22
apples       egremont_russet    1.46
apples       braeburn           1.38
apples       gala               1.23
blackberries blackberries       15.35
blueberries  blueberries        12.19
pears        conference         1.22
pears        doyenne_du_comice  1.17
plums        all_other          1.52
raspberries  raspberries        13.16
strawberries strawberries       4.08
..
```
```SQL
.s.sp["select item,variety, price from fvprices where category=$1 and price<$2"](`fruit;2.00);
```
```
item   variety            price
-------------------------------
apples bramleys_seedling  1.27
apples coxs_orange_group  1.22
apples egremont_russet    1.46
apples braeburn           1.38
apples gala               1.23
pears  conference         1.22
pears  doyenne_du_comice  1.17
plums  all_other          1.52
apples bramleys_seedling  1.35
apples coxs_orange_group  1.36
..
```

To define a function that you woudl like to use repeatedly with different parameters, you can use `.s.sq` to define the function, giving null values for the parameters:
```SQL
query:.s.sq["select * from fvprices where item=$1 and price<$2"](`;0n);
```

And then use `.s.sx` to call that function with whichever parameters you need:
```q
.s.sx[query](`apples;0.6)
```
```
category item   variety            date       unit price
--------------------------------------------------------
fruit    apples coxs_orange_group  2023.09.08 kg   0.5
fruit    apples other_late_season  2022.08.12 kg   0.58
fruit    apples braeburn           2021.09.24 kg   0.53
fruit    apples braeburn           2021.07.02 kg   0.5
fruit    apples other_mid_season   2019.10.11 kg   0.59
fruit    apples braeburn           2019.08.23 kg   0.55
fruit    apples other_late_season  2019.01.18 kg   0.57
fruit    apples other_late_season  2019.01.11 kg   0.54
fruit    apples other_late_season  2018.12.14 kg   0.58
fruit    apples other_mid_season   2018.11.23 kg   0.32
fruit    apples other_mid_season   2018.11.02 kg   0.37
fruit    apples other_mid_season   2018.10.26 kg   0.37
fruit    apples other_early_season 2018.10.12 kg   0.44
fruit    apples other_early_season 2018.10.05 kg   0.52
fruit    apples other_early_season 2018.09.21 kg   0.53
```
```q
.s.sx[query](`beans;1.4)
```
```
category  item  variety         date       unit price
-----------------------------------------------------
vegetable beans broad           2020.10.23 kg   1.35
vegetable beans broad           2020.10.16 kg   1.28
vegetable beans broad           2020.10.09 kg   1.33
vegetable beans broad           2020.09.25 kg   1.34
vegetable beans broad           2020.09.18 kg   1.34
vegetable beans broad           2019.11.01 kg   1.12
vegetable beans broad           2019.10.25 kg   1.15
vegetable beans broad           2019.10.18 kg   1.27
vegetable beans broad           2019.10.11 kg   1.26
vegetable beans runner_climbing 2019.10.11 kg   1.08
vegetable beans broad           2019.09.20 kg   1.3
vegetable beans runner_climbing 2019.09.13 kg   1.34
vegetable beans broad           2019.09.06 kg   1.36
..
```

## 4. Integrate with q

Sometimes, it may be easier to use a function that exists in the q language. 

In the code below, we are looking at an example of creating a pivot table – something that is relatively straightforward and simple to do in just a few lines of q code. 
```q
pivotprices:{[]
  //Remove the "." from the column names (dates) because SQL does not like dots in column names
  pp:update date:`$"_" sv '"." vs' string[date] from select variety, price, date from fvprices; 
  //Pull out the date column into distinct values that will become individual columns in the pivot table
  D:asc exec distinct date from pp;
  //Create the dictionary mappings
  B: exec D#(date!price) by variety:variety from pp;
  //Add the remaining columns back into the table
  A:select variety, category,item,unit from fvprices; 
  A lj B
};
pivotprices[]
```
We can then call that q function from within the SQL code
```SQL
s)select * from qt('{pivotprices[]}[]')
```
```
variety                category  item                 unit 2017_11_03 2017_11_10 2017_11_17 2017_11_24 2017_12_01 2017_12_08 2017_12_15 2017_12_22 2018_01_12 2018_01_19 2018_01_26 2018_..
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------..
bramleys_seedling      fruit     apples               kg   0.73       0.78       0.73       0.74       0.78       0.77       0.72       0.75       0.79       0.83       0.78       0.79 ..
coxs_orange_group      fruit     apples               kg   0.75       0.72       0.75       0.71       0.75       0.71       0.77       0.78       0.82       0.78       0.76       0.77 ..
egremont_russet        fruit     apples               kg   0.82       0.78       0.82       0.84       0.86       0.84       0.87       0.86       1          1          0.88       0.83 ..
braeburn               fruit     apples               kg   0.64       0.61       0.69       0.7        0.72       0.71       0.7        0.71       0.78       0.77       0.7        0.75 ..
gala                   fruit     apples               kg   0.79       0.68       0.72       0.77       0.8        0.81       0.8        0.78       0.79       0.8        0.78       0.74 ..
```
## Key Takeaways

- Familiar Interface – SQL syntax can be used directly in KDB-X, lowering the barrier to entry for users coming from traditional database systems.
- Interoperability – You can query, transform, and aggregate q tables using standard SQL commands such as SELECT, WHERE, and GROUP BY.
- Multiple Execution Options – Queries can be run inline using s) or via functions such as .s.e, .s.sp, .s.sq, and .s.sx for parameterized or reusable queries.
- Integration with q – SQL can call and interact with q functions, enabling powerful hybrid workflows that combine SQL readability with q’s advanced data manipulation capabilities.
- Extensibility – SQL support in KDB-X continues to evolve, offering a foundation that may eventually be modularized for more flexible deployment.

By supporting SQL queries directly in the q environment, KDB-X empowers analysts and developers to leverage existing SQL expertise while taking advantage of kdb+’s efficiency and expressiveness.

To learn more about KDB-X modules, visit [KDB-X Module Management](https://code.kx.com/kdb-x/modules/module-framework/overview.html).
