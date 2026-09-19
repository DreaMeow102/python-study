# score = 85

# if score >= 60:
#     print("及格")
# elif score >= 80:
#     print("良好")
# elif score >= 90:
#     print("优秀")

#判断顺序错了。不应该先判断60，而是反过来。
#而且没有囊括全部情况。

score = 85

if score >= 90:
    print("优秀")
elif score >= 80:
    print("良好")
elif score >= 60:
    print("及格")
else:
    print("不及格")