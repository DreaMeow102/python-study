year = int(input("请输入年份。"))
isHYear = None

# if year/4 == 0 and year/100 == 0 or year/400 == 0:
# 我说过我算法不行的吧......本来我计算能力就很差，写代码或者逻辑能力没问题，但是计算能力很差。
# 我是想到了除法为0，但我直接用除法了。实际上是除余为零，我数学很差，所以直接用了除法。
if year % 100 == 0:
    isHYear = True
    print("该年为整百年。")
else:
    isHYear = False
    print("该年不是整百年。")

# if (year % 4 == 0 and year % 100 == 0) or (year % 400 == 0):
# 请叫我算法失误哥。
# 我真绷不住了，这玩意就差个感叹号，但我又不知道能说什么，毕竟代码就是这么个东西，差一个就全错
if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
    print(f"{year}是闰年。")
else:
    print(f"{year}不是闰年。")

#以下写一个因为我自己算法不行，所以我更喜欢的新写法。

if isHYear == False:

    if year % 4 == 0:
        print (f"{year}是闰年。1")
    else:
        print (f"{year}不是闰年。1")

else:

    if year % 400 == 0:
        print (f"{year}是闰年。2")
    else:
        print (f"{year}不是闰年。2")

# 后面的数字用于区分两种写法打印的情况。
# 我知道这种要绕一层，但我更喜欢后者的写法。