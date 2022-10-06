import * as fs from "fs"
import csv from "csvtojson"
import ObjectsToCsv from "objects-to-csv"

export function readJson(filePath: string): any {
  const raw = fs.readFileSync(filePath)
  const json = JSON.parse(raw.toString())
  return json
}

export async function readCsv(filePath: string): Promise<Array<any>> {
  return await csv().fromFile(filePath)
}

export async function writeCsv(outputPath: string, data: Array<object>) {
  const csv = new ObjectsToCsv(data)
  await csv.toDisk(outputPath, { allColumns: true })
}

export function writeJson(outputPath: string, json: any): void {
  const jsonStr = JSON.stringify(json, null, 2)
  fs.writeFileSync(outputPath, jsonStr)
}
