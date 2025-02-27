function Bounce(t)
	if (t < 1.0 / 2.75) then
		return 7.5625 * t * t;
	elseif (t < 2 / 2.75) then
		t = t - 1.5 / 2.75;
		return 7.5625 * t * t + 0.75;
	elseif (t < 2.5 / 2.75) then
		t = t - 2.25 / 2.75;
		return 7.5625 * t * t + 0.9375;
	end
	t = t -2.625 / 2.75;
	return 7.5625 * t * t + 0.984375;
end

buffer = 0
sumT = {}

for i = 1, 100 do
	local vN = Bounce(i/100)
	local dif = vN - buffer
	buffer = vN
	table.insert(sumT,dif)
end

sum = 0
for _,v in ipairs(sumT) do
	sum = sum + v
	print(v)
end
print(sum)