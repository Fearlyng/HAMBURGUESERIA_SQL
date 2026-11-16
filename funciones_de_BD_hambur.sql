USE BD_HAMBURGUESERIA
GO
-- Buscar productos por concidencia de nombre, pasado por paramtro
CREATE PROCEDURE BUSCAR_PRODUCTO(@Nombre VARCHAR(20))
AS
BEGIN
    SELECT
    *
    FROM Producto
    WHERE Nombre = @Nombre
END

GO

-- Permite Buscar las ventas que conciden con el producto, pasado por parametro
CREATE PROCEDURE BUSCAR_COMPRA_POR_PRODUCTO(@Nombre VARCHAR(20))
AS
BEGIN
    SELECT
    DV.*
    FROM Detalla_venta DV
    LEFT JOIN Producto P ON P.IDProducto = DV.IDProducto
    WHERE P.Nombre = @Nombre
END

GO

-- Permite buscar a los clientes que concidan por su nombre pasado por parametro 
CREATE PROCEDURE BUSCAR_CLIENTE_NOMBRE(@Nombre VARCHAR(50))
AS
BEGIN
    SELECT
    *
    FROM Clientes
    WHERE Nombre = @Nombre 
END
GO

-- Permite buscar a el cliente mediante su dni, pasado por parametro
CREATE PROCEDURE BUSCAR_CLIENTE_DNI(@DNI INTEGER)
AS
BEGIN
    SELECT
    *
    FROM Clientes
    WHERE DNI = @DNI 
END

GO

-- Permite buscar a los clientes que concidan por su numero de telefono pasado por parametro
CREATE PROCEDURE BUSCAR_CLIENTE_TELEFONO(@Telefono INTEGER)
AS
BEGIN
    SELECT
    *
    FROM Clientes
    WHERE Telefono = @Telefono
END

GO

-- Permite buscar a por nombre A los clientes que recibieron su pedido 
CREATE PROCEDURE BUSCAR_CLIENTE_PRODUCTO_PAGO(@Nombre VARCHAR(20))
AS
BEGIN
    SELECT
    C.*
    FROM Clientes C
    INNER JOIN Venta V ON V.IDCliente = C.IDCliente
    INNER JOIN Detalla_venta DV ON DV.IDVenta = V.IDVenta
    INNER JOIN Producto P ON P.IDProducto = DV.IDProducto
    WHERE P.Nombre = @Nombre AND V.Estado = 'Entregado'
END
GO

-- Consultar el estado de pedido: preparacion, entregado, canselado.
CREATE FUNCTION estado_de_pedido(@numeroDePedido BIGINT)
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @estadoActual VARCHAR(50)

    SELECT
    @estadoActual = estado
    FROM Venta
    WHERE IDVenta = @numeroDePedido

    RETURN @estadoActual
END

GO


-- Consulta los productos con stock
CREATE VIEW stock_de_productos AS
    SELECT *
    FROM Producto P
    WHERE P.Stock > 0;

GO

-- Consultar los distintos horarios de atención y dirección de los restaurantes.
CREATE VIEW consultar_horarios_y_direccion AS
    SELECT 
    R.HorarioApertura,
    R.HorarioSalida,
    R.Direccion
    FROM Restaurantes R

-- muetras los IDs de los detalles de venta junto al tipo de pago efectuado efectivo
GO
CREATE VIEW tipo_de_pago_efectivo AS
SELECT
DV.IDTransaccion,
DV.tipoDePago
FROM Detalla_venta DV
WHERE tipoDePago = 'efectivo'

GO

-- muetras los IDs de los detalles de venta junto al tipo de pago efectuado transferencia
CREATE VIEW tipo_de_pago_transferencia AS
SELECT
DV.IDTransaccion,
DV.tipoDePago
FROM Detalla_venta DV
WHERE tipoDePago = 'transferencia'
GO

-- se encarga de modificar el producto comprado, y verifica que lo haga el manager
CREATE PROCEDURE modificarPedido(
    @IDVENTA BIGINT,
    @IDPRODUCTO BIGINT,
    @IDEMPLEADOIGRESANTE BIGINT 
)
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION
        DECLARE @ROL VARCHAR(50) = '';
        SELECT 
        @ROL = rol 
        FROM Empleados
        WHERE IDEmpleado = @IDEMPLEADOIGRESANTE

        IF @ROL != 'manager'
            BEGIN
                PRINT('Empleado sin permisos')
            END
        ELSE
            BEGIN
                UPDATE Detalla_venta
                SET IDProducto = @IDPRODUCTO
                WHERE IDVenta = @IDVENTA
            END
    COMMIT TRANSACTION

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
END CATCH
END

GO

--se encarga de canselar un pedido , y verifica que lo haga el manager
CREATE PROCEDURE canselarPedido(
    @IDVENTA BIGINT,
    @IDEMPLEADOIGRESANTE BIGINT 
)
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION
        DECLARE @ROL VARCHAR(50) = '';
        SELECT 
        @ROL = rol 
        FROM Empleados
        WHERE IDEmpleado = @IDEMPLEADOIGRESANTE

        IF @ROL != 'manager'
            BEGIN
                PRINT('Empleado sin permisos')
            END
        ELSE
            BEGIN
                UPDATE Venta
                SET Estado = 'canselada'
                WHERE IDVenta = @IDVENTA
            END
    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
END CATCH
END

GO
-- se encarga de realizar una baja logica en lugar de eliminar (vaciar stock) el producto.
CREATE TRIGGER bajaLogicaProducto ON Producto
INSTEAD OF DELETE
AS
BEGIN

    UPDATE P
    SET P.Stock = 0
    FROM Producto P
    INNER JOIN deleted D
        ON P.IDProducto = D.IDProducto

END

GO

-- Se encarga de verificar que los datos pasados al insert se carguen en relacion a cierta estructura.
-- tambien verifica si ya existe el producto, en tal caso aumenta el stock en lugar de añadir un producto nuevo.

CREATE TRIGGER cargarProducto ON Producto
INSTEAD OF INSERT
AS
BEGIN

    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE Nombre IS NULL OR Nombre = ''
    )
    BEGIN
        PRINT('Campo Nombre vacio')
        RETURN
    END

    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE Descripcion IS NULL
    )
    BEGIN
        PRINT('Campo Descripcion vacio')
        RETURN
    END

    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE Precio IS NULL OR Precio <= 0
    )
    BEGIN
        PRINT('Campo Precio no valido')
        RETURN
    END

    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE Stock IS NULL OR Stock < 0
    )
    BEGIN
        PRINT('Campo Stock no puede ser negativo')
        RETURN
    END

    IF EXISTS (
        SELECT 1
        FROM inserted I
        WHERE NOT EXISTS (
            SELECT 1
            FROM CategoriaProducto C
            WHERE C.IDCategoria = I.IDCategoria
        )
    )
    BEGIN
        PRINT('Categoria no encontrada')
        RETURN
    END

    UPDATE P
    SET P.Stock = P.Stock + I.Stock
    FROM Producto P
    INNER JOIN inserted I
        ON P.Nombre = I.Nombre


    INSERT INTO Producto (Nombre, Descripcion, Precio, Stock, IDCategoria)
    SELECT I.Nombre,I.Descripcion,I.Precio,I.Stock,I.IDCategoria
    FROM inserted I
    WHERE NOT EXISTS (
        SELECT 1
        FROM Producto P
        WHERE P.Nombre = I.Nombre
    )

    PRINT('Productos procesados')

END

drop TRIGGER cargarProducto
GO

-- Se encarga de verificar que los datos pasados
-- al insert se carguen en relacion a cierta estructura.
CREATE TRIGGER cargarEmpleado ON Empleados
INSTEAD OF INSERT
AS
BEGIN
    -- Validar nombres
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE Nombre IS NULL
        OR Nombre LIKE '%[^a-zA-Z ]%'
    )
    BEGIN
        PRINT('Nombre Incorrecto.')
        RETURN
    END

    -- Validar DNI
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE DNI NOT BETWEEN 10000000 AND 99999999
        OR DNI IS NULL
    )
    BEGIN
        PRINT('Debe contener 8 digitos.')
        RETURN
    END

    -- Validar roles
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE Rol NOT IN ('cajero', 'cocinero', 'gerente', 'manager')
        OR Rol IS NULL
    )
    BEGIN
        PRINT('Rol Incorrecto.')
        RETURN
    END

    -- Validar restaurantes
    IF EXISTS (
        SELECT 1
        FROM inserted I
        WHERE I.IDRestaurante IS NULL
        OR NOT EXISTS (
            SELECT 1
            FROM Restaurantes R
            WHERE R.IDRestaurante = I.IDRestaurante
        )
    )
    BEGIN
        PRINT('Restaurante Incorrecto.')
        RETURN
    END

    -- Insertar todos los registros
    INSERT INTO Empleados (Nombre, DNI, Rol, IDRestaurante)
    SELECT Nombre, DNI, Rol, IDRestaurante
    FROM inserted;

    PRINT('Carga de empleados correcta.')
END

GO

-- Se encarga de verificar la existencia de:
--- la venta pasado en el insert
--- El producto pasado en el insert
-- tambien se encarga de cargar el precio unitario en relacion al producto comprado.
CREATE TRIGGER verificarExistenciaDetalleVenta
ON Detalla_venta
INSTEAD OF INSERT
AS
BEGIN

    IF EXISTS (
        SELECT 1
        FROM inserted I
        WHERE NOT EXISTS (
            SELECT 1
            FROM Venta V
            WHERE V.IDVenta = I.IDVenta
        )
    )
    BEGIN
        PRINT('Venta cargada no existe')
        RETURN
    END

    IF EXISTS (
        SELECT 1
        FROM inserted I
        WHERE NOT EXISTS (
            SELECT 1
            FROM Producto P
            WHERE P.IDProducto = I.IDProducto
        )
    )
    BEGIN
        PRINT('Producto cargado no existe')
        RETURN
    END

    INSERT INTO Detalla_venta(cantidaVendida,IDVenta,IDProducto,tipoDePago,precioUnitario)
    SELECT I.cantidaVendida,I.IDVenta,I.IDProducto,I.tipoDePago,P.Precio
    FROM inserted I
    INNER JOIN Producto P ON P.IDProducto = I.IDProducto
    PRINT('Detalles de venta cargados')

END

GO

-- Se encarga de verificar la existencia de:
--- El cliente pasado en el insert
--- El Restaurante pasado en el insert
-- -El Empleado pasado en el insert
CREATE TRIGGER verificarExistenciaVenta ON venta
INSTEAD OF INSERT
AS
BEGIN
        IF EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN Clientes c ON c.IDCliente = i.IDCliente
        WHERE c.IDCliente IS NULL
        )
        BEGIN
            PRINT('Cliente no encontrado');
            RETURN;
        END

        IF EXISTS (
            SELECT 1
            FROM inserted i
            LEFT JOIN Restaurantes r ON r.IDRestaurante = i.IDRestaurante
            WHERE r.IDRestaurante IS NULL
        )
        BEGIN
            PRINT('Restaurante no encontrado');
            RETURN;
        END

        IF EXISTS (
            SELECT 1
            FROM inserted i
            LEFT JOIN Empleados e ON e.IDEmpleado = i.IDEmpleadoResponsable
            WHERE e.IDEmpleado IS NULL
        )
        BEGIN
            PRINT('Empleado no encontrado');
            RETURN;
        END

        INSERT INTO Venta(IDCliente, FechaVenta, IDEmpleadoResponsable, IDRestaurante, Estado, modalidadConsumo)
        SELECT IDCliente, FechaVenta, IDEmpleadoResponsable, IDRestaurante, Estado, modalidadConsumo
        FROM inserted

END
