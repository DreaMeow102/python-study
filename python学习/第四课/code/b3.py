score = input("请用数字输入你的分数。")
# 我的习惯是每个代码块用行分一下。如果是实现类似函数的代码块，那么就共用。
# 不是的话，也要做区分。除此之外，实现部分共用的，我也会做这种操作。
# float(score) 错误代码。
score = float(score) #学聪明了，返回值。
#我就不硬编码分数了，这个可以input，更好些。

if score >= 90:
    print("优秀")
elif score >= 80:
    print("良好")
elif score >= 60:
    print("及格")
else:
    print("不及格")