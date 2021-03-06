import Foundation

class Reader {
    enum Errors : Error {
        case eof
        case overflow(Int)
    }

    let data: Data
    let offset: Int
    
    var log = false
    
    var i: Int = 0 {
        didSet {
            if log && oldValue != i {
                print(String(format: "~~ buffer: %x  -- %x", i, i + offset))
            }
        }
    }
    
    init(data: Data, offset: Int = 0) {
        self.data = data
        self.offset = offset
    }
    
    func byte() throws -> UInt8 {
        if i == data.count {
            throw Errors.eof
        }
        
        let v = data[i]
        i += 1
        return v
    }

    func data(size: Int) throws -> Data {
        let overflow = i + size - data.count
        if overflow > 0 {
            throw Errors.overflow(overflow)
        }
        
        let r = Data(data[i ..< i + size])
        i += size
        return r
    }
    
    func align(alignment: Int) {
        var idx = i + offset
        
        if idx & (alignment - 1) != 0 {
            idx += alignment - (idx & (alignment - 1))
        }
        
        i = idx - offset
    }
    
    func read<T: BinaryRepresented>(_ value: T) throws -> T {
        try value.read(reader: self)
        return value
    }

}

protocol BinaryRepresented : AnyObject {
    func read(reader: Reader) throws
}

extension BinaryRepresented {
    func read(reader: Reader) throws {
        try Mirror(reflecting: self)
            .children
            .map {
                (label, value) -> BinaryRepresented in
                let binaryRep = value as? BinaryRepresented
                precondition(binaryRep != nil, "This type cannot be coneniently read")
                return binaryRep!
            }
            .forEach    { try $0.read(reader: reader) }
    }
}

protocol BinaryRepresentedBoxedValue {
    associatedtype BackingType
    
    init(from: BackingType)
}

class RepresentedEnum<BoxedType, BoxType> : BinaryRepresented
where
    BoxedType : BinaryRepresentedBoxedValue,
    BoxType : BinaryRepresented,
    BoxedType.BackingType == BoxType
{
    private let box : BoxType
    var value : BoxedType
    
    init(_ value: BoxedType, backing: BoxType) {
        self.value = value
        self.box = backing
    }
    
    func read(reader: Reader) throws {
        try box.read(reader: reader)
        value = BoxedType(from: box)
    }
}

/* - */

class BYTE : BinaryRepresented {
    var value: UInt8 = 0
    
    func read(reader: Reader) throws {
        value = try reader.byte()
    }
}

class WORD : BinaryRepresented {
    var value: UInt16 = 0
    
    func read(reader: Reader) throws {
        value =
            (UInt16(try reader.byte())     ) +
            (UInt16(try reader.byte()) << 8)
    }
}

class DWORD : BinaryRepresented {
    var value: UInt32 = 0
    
    func read(reader: Reader) throws {
        value =
            (UInt32(try reader.byte())      ) +
            (UInt32(try reader.byte()) <<  8) +
            (UInt32(try reader.byte()) << 16) +
            (UInt32(try reader.byte()) << 24)
    }
}

class LONG : DWORD {
    
}

class ResourceString : BinaryRepresented {
    
    var value = ""
    
    func read(reader: Reader) throws {
        return try read(reader: reader, initialCharacter: nil)
    }
    
    func read(reader: Reader, initialCharacter: WORD? = nil) throws {
        value = ""
        let dw = WORD()
        
        if initialCharacter?.value == 0 {
            return
        }
        
        if let s = initialCharacter.flatMap({ UnicodeScalar($0.value) }) {
            value += String(s)
        }

        while true {
            try dw.read(reader: reader)
            
            if dw.value == 0 {
                break
            }
            
            if let s = UnicodeScalar(dw.value) {
                value += String(s)
            }
        }
    }
    
}

class StringOrNumeric : BinaryRepresented {
    
    enum StringOrNumeric : Hashable {
        case numeric(Int)
        case string(String)
        
        func asString() -> String {
            switch self {
            case .numeric(let x): return "~~ NUMERIC \(x)"
            case .string(let x):  return x
            }
        }
    }
    
    var value = StringOrNumeric.numeric(0)
    
    func read(reader: Reader) throws {
        let dw = WORD()
        try dw.read(reader: reader)
        
        if dw.value == 0xffff {
            try dw.read(reader: reader)
            value = .numeric(Int(dw.value))
        }
        else {
            let string = ResourceString()
            try string.read(reader: reader, initialCharacter: dw)
            value = .string(string.value)
        }
    }
    
}

class StringOrNumericOrZero : BinaryRepresented {
    
    enum Info {
        case zero
        case numeric(Int)
        case string(String)
    }

    var value = Info.zero
    
    func read(reader: Reader) throws {
        let dw = WORD()
        try dw.read(reader: reader)
        
        if dw.value == 0x0000 {
            value = .zero
        }
        else if dw.value == 0xffff {
            try dw.read(reader: reader)
            value = .numeric(Int(dw.value))
        }
        else {
            let string = ResourceString()
            try string.read(reader: reader, initialCharacter: dw)
            value = .string(string.value)
            reader.align(alignment: 2)
        }

    }
}

enum ResourceTypes : Int, BinaryRepresentedBoxedValue {
    case HEADER       =   0
    case CURSOR       =   1
    case BITMAP       =   2
    case ICON         =   3
    case MENU         =   4
    case DIALOG       =   5
    case STRING       =   6
    case FONTDIR      =   7
    case FONT         =   8
    case ACCELERATOR  =   9
    case RCDATA       =  10
    case MESSAGETABLE =  11
    case GROUP_CURSOR =  12
    case GROUP_ICON   =  14
    case VERSION      =  16
    case DLGINCLUDE   =  17
    case PLUGPLAY     =  19
    case VXD          =  20
    case ANICURSOR    =  21
    case ANIICON      =  22
    case HTML         =  23
    case DLGINIT      = 240
    case TOOLBAR      = 241
    
    init(from value: StringOrNumeric) {
        switch value.value {
        case .numeric(let i):
            if let t = Self(rawValue: i) {
                self = t
            }
            else {
                print("unknown resource")
                abort()
            }
        case .string(let x):
            print("string resource not implemented string >>\(x)<<")
            abort()
        }

    }
}

class Alignment : BinaryRepresented {
    
    let alignment: Int
    
    init(alignment: Int) { self.alignment = alignment }
    
    func read(reader: Reader) throws {
        reader.align(alignment: alignment)
    }
}

class ResourceHeader : BinaryRepresented {
    let dataSize        = DWORD()
    let headerSize      = DWORD()
    let type            = RepresentedEnum(ResourceTypes.HEADER,
                                          backing: StringOrNumeric())
    let name            = StringOrNumeric()
    let align           = Alignment(alignment: 4)
    let dataVersion     = DWORD()
    let memoryFlags     = WORD()
    let languageId      = WORD()
    let version         = DWORD()
    let characteristics = DWORD()
}

class Resource : BinaryRepresented {
    
    let header = ResourceHeader()
    var data : (data: Data, offset: Int)? = nil
    
    func read(reader: Reader) throws {
        try header.read(reader: reader)

        let off = reader.i
        data = (try reader.data(size: Int(header.dataSize.value)), off)
        reader.align(alignment: 4)
    }
}

/* - */
	
struct WindowStyles : OptionSet, BinaryRepresentedBoxedValue {
    let rawValue: UInt32
    
    init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    init(from value: DWORD) {
        self.rawValue = value.value
    }
    
    static let WS_POPUP         = WindowStyles(rawValue: 0x80000000)
    static let WS_CHILD         = WindowStyles(rawValue: 0x40000000)
    static let WS_MINIMIZE      = WindowStyles(rawValue: 0x20000000)
    static let WS_VISIBLE       = WindowStyles(rawValue: 0x10000000)
    static let WS_DISABLED      = WindowStyles(rawValue: 0x08000000)
    static let WS_CLIPSIBLINGS  = WindowStyles(rawValue: 0x04000000)
    static let WS_CLIPCHILDREN  = WindowStyles(rawValue: 0x02000000)
    static let WS_MAXIMIZE      = WindowStyles(rawValue: 0x01000000)
    static let WS_BORDER        = WindowStyles(rawValue: 0x00800000)
    static let WS_DLGFRAME      = WindowStyles(rawValue: 0x00400000)
    static let WS_VSCROLL       = WindowStyles(rawValue: 0x00200000)
    static let WS_HSCROLL       = WindowStyles(rawValue: 0x00100000)
    static let WS_SYSMENU       = WindowStyles(rawValue: 0x00080000)
    static let WS_THICKFRAME    = WindowStyles(rawValue: 0x00040000)
    static let WS_GROUP         = WindowStyles(rawValue: 0x00020000)
    static let WS_TABSTOP       = WindowStyles(rawValue: 0x00010000)
    static let WS_MINIMIZEBOX   = WindowStyles(rawValue: 0x00020000)
    static let WS_MAXIMIZEBOX   = WindowStyles(rawValue: 0x00010000)
    
    static let BS_PUSHBUTTON      = WindowStyles([])
    static let BS_DEFPUSHBUTTON   = WindowStyles(rawValue: 0x00000001)
    static let BS_CHECKBOX        = WindowStyles(rawValue: 0x00000002)
    static let BS_AUTOCHECKBOX    = WindowStyles(rawValue: 0x00000003)
    static let BS_RADIOBUTTON     = WindowStyles(rawValue: 0x00000004)
    static let BS_3STATE          = WindowStyles(rawValue: 0x00000005)
    static let BS_AUTO3STATE      = WindowStyles(rawValue: 0x00000006)
    static let BS_GROUPBOX        = WindowStyles(rawValue: 0x00000007)
    static let BS_USERBUTTON      = WindowStyles(rawValue: 0x00000008)
    static let BS_AUTORADIOBUTTON = WindowStyles(rawValue: 0x00000009)
    static let BS_PUSHBOX         = WindowStyles(rawValue: 0x0000000A)
    static let BS_OWNERDRAW       = WindowStyles(rawValue: 0x0000000B)
    
    static let DS_ABSALIGN      = WindowStyles(rawValue: 0x00000001)
    static let DS_SYSMODAL      = WindowStyles(rawValue: 0x00000002)
    static let DS_3DLOOK        = WindowStyles(rawValue: 0x00000004)
    static let DS_FIXEDSYS      = WindowStyles(rawValue: 0x00000008)
    static let DS_NOFAILCREATE  = WindowStyles(rawValue: 0x00000010)
    static let DS_LOCALEDIT     = WindowStyles(rawValue: 0x00000020)
    static let DS_SETFONT       = WindowStyles(rawValue: 0x00000040)
    static let DS_MODALFRAME    = WindowStyles(rawValue: 0x00000080)
    static let DS_NOIDLEMSG     = WindowStyles(rawValue: 0x00000100)
    static let DS_SETFOREGROUND = WindowStyles(rawValue: 0x00000200)
    static let DS_CONTROL       = WindowStyles(rawValue: 0x00000400)
    static let DS_CENTER        = WindowStyles(rawValue: 0x00000800)
    static let DS_CENTERMOUSE   = WindowStyles(rawValue: 0x00001000)
    static let DS_CONTEXTHELP   = WindowStyles(rawValue: 0x00002000)
    static let DS_USEPIXELS     = WindowStyles(rawValue: 0x00008000)
    
    static let SS_ICON          = WindowStyles(rawValue: 0x00000003)
}

class DLGITEMTEMPLATE : BinaryRepresented {
    let style         = RepresentedEnum(WindowStyles([]), backing: DWORD())
    let extendedStyle = DWORD()
    let x             = WORD()
    let y             = WORD()
    let width         = WORD()
    let height        = WORD()
    let id            = WORD()
}

enum WindowClass : BinaryRepresentedBoxedValue {
    enum StandardWindowClass : Int {
        case button     = 0x0080
        case edit       = 0x0081
        case statictext = 0x0082
        case listbox    = 0x0083
        case scrollbar  = 0x0084
        case combobox   = 0x0085
    }
    
    case standard(StandardWindowClass)
    case custom(String)
    
    init(from: StringOrNumeric) {
        switch from.value {
        case .numeric(let n):
            if let klass = StandardWindowClass(rawValue: n) {
                self = .standard(klass)
            }
            else {
                self = .custom("unkown class \(n)")
            }
        case .string(let s):
            self = .custom(s)
        }
    }
}

class DialogItemTemplate : BinaryRepresented {

    let itemTemplate = DLGITEMTEMPLATE()
    var windowClass  = RepresentedEnum(WindowClass.standard(.button),
                                       backing: StringOrNumeric())
    let title        = StringOrNumeric()
    
    var creationData: Data? = nil
    
    func read(reader: Reader) throws {
        reader.align(alignment: 4)
        try itemTemplate.read(reader: reader)
        
        reader.align(alignment: 2)
        try windowClass.read(reader: reader)
        
        reader.align(alignment: 2)
        try title.read(reader: reader)
        
        let dataSize = try reader.read(WORD())
        
        if dataSize.value > 0 {
            creationData = try reader.data(size: Int(dataSize.value) - 2)
        }
    }
}

class DLGTEMPLATE : BinaryRepresented {
    let style         = RepresentedEnum(WindowStyles([]),
                                        backing: DWORD())
    let extendedStyle = DWORD()
    let count         = WORD()
    let x             = WORD()
    let y             = WORD()
    let width         = WORD()
    let height        = WORD()
    let menu          = StringOrNumericOrZero()
    let windowClass   = StringOrNumericOrZero()
    let title         = StringOrNumericOrZero()
}

class Dialog : BinaryRepresented {
    let template = DLGTEMPLATE()
    var items = [DialogItemTemplate]()
    
    func read(reader: Reader) throws {
        try template.read(reader: reader)
                
        if template.style.value.contains(.DS_SETFONT) {
            _ /* fontsize */ = try reader.read(WORD())
            _ /* fontname */ = try reader.read(ResourceString())
        }
        
        items = try (0 ..< template.count.value).map {
            _ in try reader.read(DialogItemTemplate())
        }

    }
}

/* - */

class BITMAPINFOHEADER : BinaryRepresented {
    enum Compression : UInt32, BinaryRepresentedBoxedValue {
        case BI_RGB       = 0x0000
        case BI_RLE8      = 0x0001
        case BI_RLE4      = 0x0002
        case BI_BITFIELDS = 0x0003
        case BI_JPEG      = 0x0004
        case BI_PNG       = 0x0005
        case BI_CMYK      = 0x000B
        case BI_CMYKRLE8  = 0x000C
        case BI_CMYKRLE4  = 0x000D
        
        init(from: DWORD) {
            self.init(rawValue: from.value)!
        }
    }

    let size = DWORD()
    let width = LONG()
    let height = LONG()
    let planes = WORD()
    let bitCount = WORD()
    let compression = RepresentedEnum(Compression.BI_RGB, backing: DWORD())
    let sizeImage = DWORD()
    let XPelsPerMeter = LONG()
    let YPelsPerMeter = LONG()
    let clrUsed = DWORD()
    let clrImportant = DWORD()
}

/* - */

class NEWHEADER : BinaryRepresented {
    let reserved = WORD()
    let resType  = WORD()
    let resCount = WORD()
}

class ICONRESDIR : BinaryRepresented {
    let width =  BYTE()
    let height =  BYTE()
    let colorCount =  BYTE()
    let reserved =  BYTE()
    let planes =  WORD()
    let bitCount =  WORD()
    let bytesInRes =  DWORD()
    let nameOrdinal =  WORD()
}

class IconGroup : BinaryRepresented {
    let header = NEWHEADER()
    var icons = [ICONRESDIR]()
    
    func read(reader: Reader) throws {
        try header.read(reader: reader)
        icons = try (0 ..< header.resCount.value).map {
            _ in try reader.read(ICONRESDIR())
        }
    }
}

/* - */

class ResourceFile {
        
    var resources = [Resource]()
    
    var dialogs    = [StringOrNumeric.StringOrNumeric : Dialog]()
    var bitmaps    = [StringOrNumeric.StringOrNumeric : Data]()
    var iconGroups = [StringOrNumeric.StringOrNumeric : IconGroup]()
    var icons      = [StringOrNumeric.StringOrNumeric : Data]()
    var strings    = [Int : String]()
    
    private func collectResource<T: BinaryRepresented>(
        _ x: Resource,
        type: T,
        into array: inout [StringOrNumeric.StringOrNumeric : T]
    ) throws
    {
        if array[x.header.name.value] != nil {
            print("already have \(T.self) named \(x.header.name.value)")
        }
        
        if let data = x.data {
            let reader = Reader(data: data.data, offset: data.offset)
            array[x.header.name.value] = try reader.read(type)
        }
        else {
            print("\(T.self) \(x.header.name.value) has no data")
        }
    }
    
    private func collectData(
        _ x: Resource,
        into array: inout [StringOrNumeric.StringOrNumeric : Data]
    ) throws
    {
        if array[x.header.name.value] != nil {
            print("already have data named \(x.header.name.value)")
        }
        
        if let data = x.data {
            array[x.header.name.value] = data.data
        }
        else {
            print("\(x.header.name.value) has no data")
        }
    }

    private func parseStrings(resource: Resource) throws {
        guard
            case let StringOrNumeric.StringOrNumeric.numeric(name) = resource.header.name.value,
            let data = resource.data?.data
        else {
            return
        }
    
        let r = Reader(data: data)
        let len = WORD()
        
        for i in 0 ..< 16 {
            try len.read(reader: r)
            
            guard len.value != 0 else {
                continue
            }
            
            let stringId   = (name - 1) * 16 + i
            let stringData = try r.data(size: Int(len.value * 2))
            let string     = String(data: stringData, encoding: .utf16LittleEndian) ?? "[ENCODING ERROR]"
            
            strings[stringId] = string
        }
    }
    
    func load(url: URL) throws {
        let data = try Data(contentsOf: url)
        let reader = Reader(data: data)
        
        while true {
            let x = Resource()
            
            do {
                try x.read(reader: reader)
            }
            catch (Reader.Errors.eof) {
                break
            }
                        
            resources.append(x)
            
            switch x.header.type.value {
             
            case .HEADER:
                continue
                
            case .DIALOG:
                try collectResource(x, type: Dialog(), into: &dialogs)
                
            case .BITMAP:
                try collectData(x, into: &bitmaps)

            case .GROUP_ICON:
                try collectResource(x, type: IconGroup(), into: &iconGroups)
                
            case .ICON:
                try collectData(x, into: &icons)
            
            case .STRING:
                try parseStrings(resource: x)
                
            case .MENU:
                continue
                
            case .CURSOR:       fallthrough
            case .FONTDIR:      fallthrough
            case .FONT:         fallthrough
            case .ACCELERATOR:  fallthrough
            case .RCDATA:       fallthrough
            case .MESSAGETABLE: fallthrough
            case .GROUP_CURSOR: fallthrough
            case .VERSION:      fallthrough
            case .DLGINCLUDE:   fallthrough
            case .PLUGPLAY:     fallthrough
            case .VXD:          fallthrough
            case .ANICURSOR:    fallthrough
            case .ANIICON:      fallthrough
            case .HTML:         fallthrough
            case .DLGINIT:      fallthrough
            case .TOOLBAR:
                print(x.header.type.value)
            }
            
        }
        
    }
    
    func iconData(named name: String) -> Data? {
        guard let ordinal = iconGroups[.string(name)]?.icons.first?.nameOrdinal else {
            return nil
        }
        
        return icons[.numeric(Int(ordinal.value))]
    }
    
}
