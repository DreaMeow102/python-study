nums = [3, 8, 12, 5, 20, 7]
# a = 0 我原先想的是用0做比较然后一点点替换0 ，看来是不行的，必须得是数组内数字
a = nums[0]
for b in nums:
    # if a >= b :
    #     b = a
    # 错误逻辑。
    if b > a:
        a = b
print (a)