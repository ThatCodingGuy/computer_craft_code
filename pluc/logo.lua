mon = peripheral.wrap("left")
mon.clear()
mon.setTextScale(0.5)
term.redirect(mon)
while true do
    image = paintutils.loadImage("/gitlib/turboCo/logo.txt")
    paintutils.drawImage(image, 0, 0)
    sleep(30)
end