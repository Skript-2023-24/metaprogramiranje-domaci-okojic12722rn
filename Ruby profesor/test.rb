id = "1OthgBsGuDBLUhLhIa2O0rQbjpD5GaDpuLsj2ZcGvgNY"

require "google_drive"

sesija = GoogleDrive::Session.from_config("config.json")

list = sesija.spreadsheet_by_key(id).worksheets[0]

class SheetTable
  include Enumerable

  def initialize(list_data, id, sesija)
    @data = list_data
    @spreadsheet_id = id
    @session = sesija
  end

  def [](naziv_kolone)
    zaglavlje = @data.rows.first
    kolona_index = zaglavlje.index(naziv_kolone)
    @data.rows.map { |row| row[kolona_index] }
  end

  def []=(naziv_kolone, red_index, vrednost)
    zaglavlje = @data.rows.first
    kolona_index = zaglavlje.index(naziv_kolone)
    @data[red_index + 1, kolona_index + 1] = vrednost
    @data.save
  end

  def row(index)
    @data.rows[index - 1]
  end

  def each
    @data.rows.map do |row|
      next if row.empty? || sadrzi_total_ili_subtotal?(row)
      row.map { |cell| yield cell }
    end
  end

  def niz
    @data.rows
  end

  def sadrzi_total_ili_subtotal?(row)
    row.any? { |cell| cell.to_s.downcase.include?("total") || cell.to_s.downcase.include?("subtotal") }
  end

  def zaglavlja
    @data.rows.first
  end

  def rows
    @data.rows.drop(1)
  end
#a
  def +(other)
    raise 'Zaglavlja nisu ista' unless zaglavlja == other.zaglavlja

    combined_rows = (rows + other.rows).uniq
    SheetTable.new_sheet_with_combined_rows(@session, 
                                            @spreadsheet_id, 
                                            "Prva+Druga", 
                                            zaglavlja, 
                                            combined_rows)
  end

  def self.new_sheet_with_combined_rows(sesija, id, new_sheet_title, zaglavlja, combined_rows)
    spreadsheet = sesija.spreadsheet_by_key(id)
    new_ws = spreadsheet.add_worksheet(new_sheet_title)
    new_ws.update_cells(1, 1, [zaglavlja])
    new_ws.update_cells(2, 1, combined_rows)
    new_ws.save
  end

  def -(other)
    raise 'Zaglavlja nisu ista' unless zaglavlja == other.zaglavlja

    unique_rows = rows.reject do |row_t2|
      other.rows.any? { |row_t1| row_t2 == row_t1 }
    end
    SheetTable.new_sheet_with_combined_rows(@session, 
                                            @spreadsheet_id, 
                                            "Prva - Druga", 
                                            zaglavlja, 
                                            unique_rows)
  end
end

prvi_list = SheetTable.new(list, id, sesija)

red_podaci = prvi_list.row(1)

prvi_list["Prva Kolona", 2] = 123

kolona_podaci = prvi_list["Druga Kolona"]

niz_podaci = prvi_list.niz

list2 = sesija.spreadsheet_by_key(id).worksheets[1]

drugi_list = SheetTable.new(list2, id, sesija)

kombinacija1 = prvi_list + drugi_list

kombinacija2 = prvi_list - drugi_list