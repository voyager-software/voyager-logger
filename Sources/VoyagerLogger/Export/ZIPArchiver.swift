//
//  ZIPArchiver.swift
//  VoyagerLogger
//
//  Created by Gábor Sajó on 2026-04-12.
//

import Foundation
import Compression

/// Minimal, portable ZIP archive writer.
///
/// Produces valid ZIP files with stored or deflated entries.
/// No encryption, no zip64 — intentionally simple for bundling log files.
enum ZIPArchiver {
    // MARK: Internal

    /// Creates a ZIP archive from the given `files` and returns it as `Data`.
    static func archive(files: [URL]) throws -> Data {
        var archive = Data()
        var centralDirectory = Data()
        var localFileOffset: UInt32 = 0

        let dosDate = self.dosDateTime(from: Date())

        for fileURL in files {
            let fileData = try Data(contentsOf: fileURL)
            let fileName = fileURL.lastPathComponent
            let fileNameData = Data(fileName.utf8)

            // Deflate
            let compressed = self.deflate(fileData)
            let useDeflate = compressed.count < fileData.count
            let payload = useDeflate ? compressed : fileData
            let method: UInt16 = useDeflate ? 8 : 0 // 8 = deflate, 0 = stored

            let crc = self.crc32(fileData)

            // Local file header
            var local = Data()
            local.appendUInt32(0x0403_4B50) // signature
            local.appendUInt16(20) // version needed
            local.appendUInt16(0) // flags
            local.appendUInt16(method)
            local.appendUInt16(dosDate.time)
            local.appendUInt16(dosDate.date)
            local.appendUInt32(crc)
            local.appendUInt32(UInt32(payload.count))
            local.appendUInt32(UInt32(fileData.count))
            local.appendUInt16(UInt16(fileNameData.count))
            local.appendUInt16(0) // extra field length
            local.append(fileNameData)
            local.append(payload)

            // Central directory entry
            var central = Data()
            central.appendUInt32(0x0201_4B50) // signature
            central.appendUInt16(20) // version made by
            central.appendUInt16(20) // version needed
            central.appendUInt16(0) // flags
            central.appendUInt16(method)
            central.appendUInt16(dosDate.time)
            central.appendUInt16(dosDate.date)
            central.appendUInt32(crc)
            central.appendUInt32(UInt32(payload.count))
            central.appendUInt32(UInt32(fileData.count))
            central.appendUInt16(UInt16(fileNameData.count))
            central.appendUInt16(0) // extra field length
            central.appendUInt16(0) // comment length
            central.appendUInt16(0) // disk number start
            central.appendUInt16(0) // internal attributes
            central.appendUInt32(0) // external attributes
            central.appendUInt32(localFileOffset)
            central.append(fileNameData)

            localFileOffset += UInt32(local.count)
            archive.append(local)
            centralDirectory.append(central)
        }

        // End of central directory record
        var eocd = Data()
        eocd.appendUInt32(0x0605_4B50) // signature
        eocd.appendUInt16(0) // disk number
        eocd.appendUInt16(0) // disk with central dir
        eocd.appendUInt16(UInt16(files.count))
        eocd.appendUInt16(UInt16(files.count))
        eocd.appendUInt32(UInt32(centralDirectory.count))
        eocd.appendUInt32(UInt32(archive.count))
        eocd.appendUInt16(0) // comment length

        archive.append(centralDirectory)
        archive.append(eocd)

        return archive
    }

    // MARK: Private

    // MARK: - DOS date/time

    private struct DosDateTime { let time: UInt16; let date: UInt16 }

    private static let crc32Table: [UInt32] = (0 ..< 256).map { i -> UInt32 in
        var c = UInt32(i)
        for _ in 0 ..< 8 {
            c = (c & 1) != 0 ? 0xEDB8_8320 ^ (c >> 1) : c >> 1
        }
        return c
    }

    // MARK: - Deflate

    private static func deflate(_ input: Data) -> Data {
        input.withUnsafeBytes { (src: UnsafeRawBufferPointer) -> Data in
            let bound = src.bindMemory(to: UInt8.self)
            let capacity = input.count + max(input.count / 1000, 12) + 18
            var output = [UInt8](repeating: 0, count: capacity)

            var stream = compression_stream(
                dst_ptr: UnsafeMutablePointer<UInt8>.allocate(capacity: 0),
                dst_size: 0,
                src_ptr: bound.baseAddress!,
                src_size: input.count,
                state: nil
            )
            let status = compression_stream_init(&stream, COMPRESSION_STREAM_ENCODE, COMPRESSION_ZLIB)
            guard status == COMPRESSION_STATUS_OK else { return input }
            defer { compression_stream_destroy(&stream) }

            stream.src_ptr = bound.baseAddress!
            stream.src_size = input.count

            return output.withUnsafeMutableBufferPointer { buf in
                stream.dst_ptr = buf.baseAddress!
                stream.dst_size = capacity

                let finalStatus = compression_stream_process(&stream, Int32(COMPRESSION_STREAM_FINALIZE.rawValue))
                guard finalStatus == COMPRESSION_STATUS_END else { return input }

                let written = capacity - stream.dst_size
                guard written > 0 else { return input }
                return Data(buf[..<written])
            }
        }
    }

    // MARK: - CRC-32

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        let table = self.crc32Table
        for byte in data {
            let idx = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = table[idx] ^ (crc >> 8)
        }
        return crc ^ 0xFFFF_FFFF
    }

    private static func dosDateTime(from date: Date) -> DosDateTime {
        let cal = Calendar.current
        let c = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let year = UInt16(max((c.year ?? 1980) - 1980, 0))
        let month = UInt16(c.month ?? 1)
        let day = UInt16(c.day ?? 1)
        let hour = UInt16(c.hour ?? 0)
        let minute = UInt16(c.minute ?? 0)
        let second = UInt16((c.second ?? 0) / 2)
        return DosDateTime(
            time: (hour << 11) | (minute << 5) | second,
            date: (year << 9) | (month << 5) | day
        )
    }
}

// MARK: - Data helpers

private extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        var v = value.littleEndian
        append(contentsOf: Swift.withUnsafeBytes(of: &v, Array.init))
    }

    mutating func appendUInt32(_ value: UInt32) {
        var v = value.littleEndian
        append(contentsOf: Swift.withUnsafeBytes(of: &v, Array.init))
    }
}
