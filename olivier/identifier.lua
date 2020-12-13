
turtle.select(1)

while true do
  turtle.suckUp()
  if turtle.getItemCount() > 0 then
    print(textutils.serializeJSON(turtle.getItemDetail()))
    turtle.drop()
  end
end