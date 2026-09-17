# 跑完之后b和a等同（意思是他和a成为了一体，共享数组，最后结果都是a和b输出为1 2 3 9）
a = [1, 2, 3]
b = a
b.append(9)
print(a)
print(b)