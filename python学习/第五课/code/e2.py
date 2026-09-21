# 这里是对continue语句的使用。这边是跳过该循环。根据题目，我们定义一个range循环1-5(实际写要到6)
# 这里没什么多余的思路，可以直接写：
for a in range(1,6):
    if a == 3:
        continue
        # print (a) 我特么缩进搞错了，自检才查出来。
    print (a)