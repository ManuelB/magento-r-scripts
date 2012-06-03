# load RMySQL library
# if not available execute install.packages("RMySQL")
library(RMySQL)
con <- dbConnect(MySQL(), user="root", password="xxx", 
                 dbname="local", host="127.0.0.1")

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

itemCounts <- aggregate(orderItems$sku, by=list(order=orderItems$sku), FUN=length)

hist(itemCounts$x, breaks=300)

# Topseller
topseller <- itemCounts[order(itemCounts$x, decreasing=TRUE),][1:10,]

barplot(height=topseller$x, names.arg=topseller$order)
# Hole alle Bestellungen mit der totalen Summe
orderTotals <- dbGetQuery(con, "select base_grand_total as total, customer_email as email, CONCAT(customer_firstname, \" \", customer_lastname) as name from sales_flat_order")
# Zeige alle BEstellungen bis 400 ??? als Histogramm
hist(subset(orderTotals, total < 400)$total, breaks=100)
mean(orderTotals$total)

customerSpendingsByEmail <- aggregate(orderTotals$total, by=list(email=orderTotals$email), FUN=sum)
customerMeanByEmail <- aggregate(orderTotals$total, by=list(email=orderTotals$email), FUN=mean)
customerSpendingsByName <- aggregate(orderTotals$total, by=list(name=orderTotals$name), FUN=sum)
customerMeanByName <- aggregate(orderTotals$total, by=list(email=orderTotals$name), FUN=mean)

# Wieviel geben Kunden insgesamt aus
hist(customerSpendingsByName$x, breaks=100)

clicks <- dbGetQuery(con, "select * from log_url lu, log_url_info lui, log_visitor lv, log_visitor_info lvi WHERE lu.url_id = lui.url_id AND lu.visitor_id = lv.visitor_id AND lu.visitor_id = lvi.visitor_id")


# disconnect from database
dbDisconnect(con)