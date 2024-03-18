﻿INSERT INTO dbo.PurchaseHeader (PurchaseHeaderID, UnitID, BusinessDate)
    VALUES
        -- Units are same for all examples
        ('A1F17EA7-7D3B-4EF2-848E-6286E0651E3B', 1, '2023-12-07'),
        ('7F63B0AD-31E0-4A3C-8A69-5CE74F56814A', 1, '2023-12-06'),
        ('129193F9-57E5-4335-B474-EF188A3166ED', 1, '2023-12-05'),
        ('6CE7551D-251E-4B5E-97FB-AD2E4D4093D1', 1, '2023-12-04'),
        ('C94527E6-8C24-4CAA-946D-E2901E6AE509', 1, '2023-12-03')
;

INSERT INTO dbo.PurchaseLine (PurchaseLineID, PurchaseHeaderID, ItemID, Quantity, Cost)
    VALUES
        -- Example 1
        ('BA63EC32-A312-434B-B867-AB2DD3315C30', 'A1F17EA7-7D3B-4EF2-848E-6286E0651E3B', 1, 40, 15),
        ('F89482DA-93FA-48E6-B0CA-5F5F11D9EF0A', '7F63B0AD-31E0-4A3C-8A69-5CE74F56814A', 1, 25, 20),
        -- Example 2
        ('559F312C-5F94-4BD4-87EE-8A0C2E3DEB2D', 'A1F17EA7-7D3B-4EF2-848E-6286E0651E3B', 2, 40, 15),
        ('BC64BD76-F05F-4B89-8B87-D2879F23D17F', '7F63B0AD-31E0-4A3C-8A69-5CE74F56814A', 2, 25, 20),
        ('B5AB425D-E740-4B02-93EA-BC8D19745154', '129193F9-57E5-4335-B474-EF188A3166ED', 2, 45, 08),
        -- Example 3
        ('6358C803-77F1-4FC7-9990-99488942DC20', 'A1F17EA7-7D3B-4EF2-848E-6286E0651E3B', 3, 40, 15),
        ('5BB51963-0CEC-4E29-8E38-3223EACFB0DD', '7F63B0AD-31E0-4A3C-8A69-5CE74F56814A', 3, 25, 20),
        -- Example 4
        ('E8A08602-6C53-490A-A099-E878314071FA', 'A1F17EA7-7D3B-4EF2-848E-6286E0651E3B', 4, 40, 15),
        ('25DE2FE2-11E3-476F-9514-EFF1E30B6102', '7F63B0AD-31E0-4A3C-8A69-5CE74F56814A', 4, 25, 20),
        -- Example 4
        ('D38181C6-1792-484E-819B-79BCC61CABB2', 'A1F17EA7-7D3B-4EF2-848E-6286E0651E3B', 5, 40, 15),
        ('D507FCF1-D86A-4AE6-A511-CADC9469985A', '7F63B0AD-31E0-4A3C-8A69-5CE74F56814A', 5, 25, 20),
        ('5DB398AE-412B-4085-9406-65BE5073E595', '129193F9-57E5-4335-B474-EF188A3166ED', 5, 30, 20),
        ('035BE196-0A8D-4AAA-9928-7FAB8A2E39FD', '6CE7551D-251E-4B5E-97FB-AD2E4D4093D1', 5, 45, 18),
        ('09F68336-5ADC-4409-99F4-29B5D8D5DCBB', 'C94527E6-8C24-4CAA-946D-E2901E6AE509', 5, 20, 17)
;

INSERT INTO dbo.Inventory (UnitID, BusinessDate, ItemID, Quantity, Cost)
    VALUES
        -- Example 1
        (1, '2023-12-08', 1, 100, 0),
        (1, '2023-12-01', 1, 50, 10),
        (1, '2023-11-24', 1, 20, 8),
        -- Example 2
        (1, '2023-12-08', 2, 100, 0),
        (1, '2023-12-01', 2, 50, 10),
        (1, '2023-11-24', 2, 20, 8),
        -- Example 3
        (1, '2023-12-08', 3, 100, 0),
        (1, '2023-12-01', 3, 20, 10),
        (1, '2023-11-24', 3, 20, 8),
        -- Example 4
        (1, '2023-12-01', 4, 20, 10),
        (1, '2023-11-24', 4, 20, 8),
        -- Example 5
        (1, '2023-12-08', 5, 100, 0),
        (1, '2023-12-01', 5, 50, 10),
        (1, '2023-11-24', 5, 20, 8)
;

INSERT INTO dbo.ItemsToCalcCost (ItemID)
    VALUES (1),
           (2),
           (3),
           (4),
           (5)
;
