# age = 20
age = 15
haveTicket = True
age18 = None

if age >= 18:
    print ("已经成年。")
    age18 = True

    # if haveTicket = True: (忘记了=是赋值，报错如下。)
#       File "D:\studydemo\python学习\第四课\code\d1.py", line 7
#     if haveTicket = True:
#        ^^^^^^^^^^^^^^^^^
# SyntaxError: invalid syntax. Maybe you meant '==' or ':=' instead of '='?
# 不过这个错误我一眼就看出来了，并不算大。
    if haveTicket == True: 
        print("已成年，也已有票，可以入场。")
    else:
        print("已成年，但没有票，不能入场。")

else:
    age18 = False
    print ("未成年，不能入场。")

print (age,haveTicket,age18)
# 这里这个age18的变量其实对于题目是多余的，我自己大致在考试的时候也不会这么写。
# 但我认为这个和实际上做项目有关，面对对象、面对变量等，这些还是需要的。所以我实际上就做了这个“代码升级”。