a = input("第一笔支出：")
b = input("第二笔支出：")
c = input("第三笔支出：")
# float (a,b,c) 错误代码。报错为：
# Traceback (most recent call last):
#   File "D:\studydemo\python学习\复习一\code\yi1.py", line 4, in <module>
#     float (a,b,c)
#     ~~~~~~^^^^^^^
# TypeError: float expected at most 1 argument, got 3
# float (a)
# float (b)
# float (c)
# 之前在这个位置，似乎报错。
# d = [a,b,c] 这个写法似乎要不得。(已被更正。)
a = float (a)
b = float (b)
c = float (c)
d = [a,b,c]
# d.append(a)
# d.append(b)
# d.append(c)
# 这些屎山写法可以不要了。
print(f"共{len(d):.0f}笔。")
# print(f"总额{sum(d):.2f}元。") 第一次报错的地方。
# print(f"平均{sum(d)/len(d):.2f}元。") 第一次报错的地方。
print(f"总额{sum(d):.2f}元。")
print(f"平均{sum(d)/len(d):.2f}元。")
print(f"最大{max(d):.2f}元，最小{min(d):.2f}元。")

# 以下这坨估计超纲了。但我挑战一下。
# if(a>50,b>50,c>50):
#     print(f"有超过50的吗:Ture")
# else:
#     print(f"有超过50的吗:False")
# 不挑战了。毕竟没学if判断。
# print ("有超过50的吗？"a>50,b>50,c>50) 以前的不完美写法。
print (f"有超过50的吗：{max(d)>50}")
#够磕磕绊绊的。不过完成就是好事。