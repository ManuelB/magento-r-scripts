# load RMySQL library
# if not available execute install.packages("RMySQL")
library(RMySQL)
con <- dbConnect(MySQL(), user="root", password="", 
                  dbname="magento_16", host="127.0.0.1")

# executed query to get data from magento
orderItems <- dbGetQuery(con, "select order_id, sku from sales_flat_order_item")
# get some very basic information about the just received data
summary(orderItems)

# load arules package for automatically learning rules
# if not available execute install.packages("arules")
library(arules)

# Create a list for every order containing the SKUs ordered
order2Items <- aggregate(orderItems$sku, by=list(order=orderItems$order_id), FUN=list)
# Kick out duplicate from list and transform structure to transactions
transactions <- as(lapply(order2Items$x, unique), "transactions")
## Mine itemsets with Eclat (tidLists crashed when support is nearly 0).
fsets <- eclat(transactions, parameter = list(support = 0.002))
# have a look into the found frequent item sets
inspect(sort(fsets))

# e.g.
# items                    support
# 1 {ALTES_SYSTEM_IMPORT} 0.67272727
# 2 {28000-500}           0.20000000
# 3 {VGN-TXN27N/B}        0.03636364
# 4 {28000-250}           0.03636364
# 5 {VGN-TXN27N/B,                  
#    ac-66332}            0.01818182
# 6 {ac-66332}            0.01818182
# 7 {28000-1000}          0.01818182
# 8 {28000-100}           0.01818182
# 9 {steve_4}             0.01818182


# disconnect from database
dbDisconnect(con)