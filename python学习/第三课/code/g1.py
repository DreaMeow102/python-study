prices = [19.9,5.5,32.0,8.8]
print (f"共 {len(prices)} 个物品。")
print (f"总价 {sum(prices):.2f} 元。")
print (f"最贵 {max(prices):.2f} 元。")
print (f"最便宜 {min(prices):.2f} 元。")
print (f"平均 {float(sum(prices)/len(prices)):.2f}元。")