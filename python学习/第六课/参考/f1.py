# @预期
# 李雷 今年 24 岁
# 李雷 今年 24 岁，李雷 明年 25 岁
# 李雷 今年 24 岁
# @结束
name = "李雷"
age = 24
print("{} 今年 {} 岁".format(name, age))
print("{0} 今年 {1} 岁，{0} 明年 {2} 岁".format(name, age, age + 1))
print("{n} 今年 {a} 岁".format(n=name, a=age))