data = [0x12, 0x3b, 0x92, 0xe2, 0x41, 0xf0, 0xe2, 0x1f, 0xef, 0xf1, 0x03, 0x3e, 0x16, 0xa6, 0x46, 0x3b, 0xdc, 0x00, 0xdd, 0xce, 0xd0, 0xb0, 0x56, 0x1e, 0x98, 0x29, 0xfa, 0x95, 0x13, 0x55, 0x25, 0x9c, 0x45, 0x2e, 0x47, 0xbd, 0x8f, 0x22, 0x98, 0xfc, 0x41, 0x74, 0x68, 0xfc, 0x65, 0x32, 0x36, 0x7b, 0xaf, 0xbc, 0xc7, 0xec, 0x60, 0x14, 0x63, 0xd3, 0xda, 0x20, 0xe3, 0xbf, 0xc4, 0x98, 0xf5, 0x32]

def GetCauldronBit(day):
    global data
    day = (day + 125) % 365
    voidState = data[day//8] & (1 << (day % 8))
    return voidState

def GetYearlyVoidList(isLeapYear=True, debug=False):
    voidList = []
    if isLeapYear:
        monthLengths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 30]
    else:
        monthLengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    i = 0
    print("Day\tMonth\t0=Void, 1=Empty")
    for m in range(len(monthLengths)):
        for j in range(monthLengths[m]):
            voidState = "0" if GetCauldronBit(i+(monthLengths[m])) else "1"
            if debug:
                print(f"{j+1}\t{m+1}\t{voidState}")
            i += 1
            voidList.append(voidState)
    return voidList

voidList = GetYearlyVoidList(isLeapYear=False)
print("norm", ''.join(str(x) for x in voidList))
voidList = GetYearlyVoidList(isLeapYear=True)
print("leap", ''.join(str(x) for x in voidList))
