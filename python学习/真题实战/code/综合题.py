a = input ("请输入成绩一。")
b = input ("请输入成绩二。")
c = input ("请输入成绩三。")
a = float (a)
b = float (b)
c = float (c)
d = [a,b,c]
print (f"一共{len(d)}门课的成绩。")
print (f"总分为{sum(d)}")
print (f"平均分为：{sum(d)/len(d):.2f}")
print (f"最高分为：{max(d)}、最低分为：{min(d)}")
print (a>=60 and b>=60 and c>=60)

#操作题我没法跑，因为是md文件。综合题跑下来是一致的。