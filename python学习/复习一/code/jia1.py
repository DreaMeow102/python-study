a = input("请输入第一个数：")
b = input("请输入第二个数：")
c = int (a) #这是报错后改的，实际上只有int(a)
d = int (b) #这是报错后改的，实际上只有int(b)
print(f"{a}+{b}={c + d}")
# print(f"{a}*{b}={a * b}") #乘号我键盘上不太好打，将就用*了。
# 我特么把乘忘了，报错如下：
# Traceback (most recent call last):
#   File "D:\studydemo\python学习\复习一\code\jia1.py", line 6, in <module>
#     print(f"{a}*{b}={a * b}") #乘号我键盘上不太好打，将就用*了。
#                      ~~^~~
# TypeError: can't multiply sequence by non-int of type 'str'
#这题很顺，几乎没什么问题。不过应该有更好的实现方式，比如将int给融入input内,或者是说有别的好写法。
print(f"{a}*{b}={c * d}")