namespace QaziCalculator.Models;

public class Product
{
    public int Id { get; set; }

    // Mahsulot nomi
    public string Name { get; set; } = string.Empty;

    // Masalan: kg, dona, litr
    public string Unit { get; set; } = "kg";

    // Sotuv narxi
    public decimal SalePrice { get; set; }

    // Hozirgi mavjud miqdor
    public double StockQuantity { get; set; }

    // Mahsulot faol yoki yo‘qligi
    public bool IsActive { get; set; } = true;

    // Yaratilgan vaqt
    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Izoh
    public string Notes { get; set; } = string.Empty;
}