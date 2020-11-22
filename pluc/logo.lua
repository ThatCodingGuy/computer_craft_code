mon = peripheral.wrap("left")
mon.clear()
mon.setTextScale(0.5)
image = paintutils.loadImage("/gitlib/turboCo/logo.txt")
term.redirect(mon)
while true do
    paintutils.drawImage(image, 1, 1)
    sleep(30)
end