USE BD_HAMBURGUESERIA
INSERT INTO CategoriaProducto(Nombre,Descripcion) VALUES 
('carne','carne de calidad'),
('vegetariano','verduradas frescas'),
('guarnicion','papas,bebidas,etc')
SELECT * FROM CategoriaProducto

INSERT INTO Producto (Nombre,Descripcion,Precio,Stock,IDCategoria) VALUES
('BigMac','tomate,lechuga,pepino,cheddar,mayonesa,carne de res',19000,10,1),
('Ensalada de rucula','una salada',1900,0,2),
('papas','balde de papas',10000,10,3),
('Haburguesa con papas','Combo para compartir',30000,11,1)
SELECT * FROM Producto

INSERT INTO Restaurantes (Direccion,HorarioApertura,HorarioSalida,Telefono) VALUES
('fuerte apache 1932', '08:00:00','22:00:00',1234567890),
('jose las paso 134', '08:00:00','21:00:00',0987654321)
SELECT * FROM Restaurantes

INSERT INTO Empleados (Nombre,DNI,Rol,IDRestaurante) VALUES 
('Gaston',45148698,'cajero',1),
('Sofia',42877181,'manager',1),
('Matias',38995017,'cocinero',1)
SELECT * FROM Empleados

INSERT INTO Clientes (Nombre,Apellido,DNI,Telefono) VALUES
('Jose','Miranda',423456987,null),
('Luis','Lopez',413456987,1146502017),
('Julia','Rodriguez',403456987,null),
('Carolina','Ledesma',393456987,1154602429)
SELECT * FROM Clientes

INSERT INTO Venta (FechaVenta, Estado, IDCliente,IDRestaurante,IDEmpleadoResponsable,modalidadConsumo) VALUES
('2026-11-12','Preparacion',1,1,2,'local'),
('2026-11-11','Entregado',1,1,1,'para llevar'),
('2026-11-11','Entregado',1,1,2,'para llevar'),
('2026-11-10','Entregado',1,1,2,'local')
SELECT * FROM Venta

INSERT INTO Detalla_venta(cantidaVendida,IDVenta,IDProducto,tipoDePago) VALUES
(2,1,1,'efectivo'),
(1,2,2,'efectivo'),
(3,3,3,'transferencia'),
(10,4,4,'transferencia')
SELECT * FROM Detalla_venta


