db=require("database")
items=db.makeTable("items","items.db")
--local items=db.makeTable("accounts","accounts.db")
orders=db.makeTable("orders","orders.db")
require("shell").execute("lua")