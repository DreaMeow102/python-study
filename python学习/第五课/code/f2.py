# total = 0 没问题。
# nums = [10, 20, 30] 数组定义，没问题。

# for n in nums:
#     total = n 这里没进行累加的逻辑。他执行的逻辑类似于替换，而不是累加。

# print(total) 同上，不过这里没什么问题——print位置也对。
# 改动如下：

total = 0
nums = [10, 20, 30]

for n in nums:
    total = total + n

print(total)

# 自检无误。