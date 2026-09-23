word = "lemon"
#word[0] = "L"
# File "D:\studydemo\python学习\第六课\code\a1.py", line 2, in <module>
#     word[0] = "L"
#     ~~~~^^^
# TypeError: 'str' object does not support item assignment

# 我们现在要输出Lemon。最好的办法是用一个新变量作为承接。
# a = word[1:] #这一步等于从1开始取该字符串。拼接到最后即可。
# a = "L" + a #拼接。
# print (a)
# 自检无误。
# 这种就是靠字符串拼接的。现在练upper。但是在我印象里，upper是没有教过的。
# 我只能靠自己摸索了。
# 注释上面的有效代码。

a = word.upper()
print (a)