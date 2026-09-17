a = input("请输入第一个价格")
float(a)
b = input("请输入第二个价格")
float(b)
c = []

#c.append(a,b) 错误写法。以下为报错。
#   File "D:\studydemo\python学习\第三课\code\d4.py", line 6, in <module>
#     c.append(a,b)
#     ~~~~~~~~^^^^^
# TypeError: list.append() takes exactly one argument (2 given)

#c.append([]) 可能是再次的错误写法

#2. 创建一个**空列表**，把这两个价格 `append` 进去（该说法是否错误？append是不是不能加脚标？）
c.append(a)
c.append(b)
#大致能理解了。你是想让我print里加。
# print(f"第一个是{(c[0]):2f}元，最后一个是{(c[-1]):2f}元。")
# print(f"第一个是{(c[0]):.2f}元，最后一个是{(c[-1]):.2f}元。")
# 以上都是因为记忆模糊而出现的错误。
print(f"第一个是{float(c[0]):.2f}元，最后一个是{float(c[-1]):.2f}元。")
