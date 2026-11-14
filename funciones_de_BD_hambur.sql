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
                RETURN
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
CREATE TRIGGER bajaLogicaProducto on Producto
INSTEAD OF DELETE
AS
BEGIN
        DECLARE @ID BIGINT = 0

        SELECT @ID = IDProducto
        FROM deleted

        UPDATE Producto
        SET Stock = 0
        WHERE IDProducto = @ID

END

GO

-- Se encarga de verificar que los datos pasados al insert se carguen en relacion a cierta estructura.
-- tambien verifica si ya existe el producto, en tal caso aumenta el stock en lugar de añadir un producto nuevo.
CREATE TRIGGER cargarProducto on Producto
INSTEAD OF INSERT
AS
BEGIN
        DECLARE @Nombre VARCHAR(50) = ''
        DECLARE @Descripcion VARCHAR(50) = ''
        DECLARE @Precio DECIMAL = 0
        DECLARE @Stock INTEGER = 0
        DECLARE @IDCategoria BIGINT = 0

        SELECT 
        @Nombre = Nombre,
        @Descripcion = Descripcion,
        @Precio = Precio,
        @Stock = Stock,
        @IDCategoria = IDCategoria
        FROM inserted

        IF @Nombre IS NULL
        BEGIN
            PRINT('campo "Nombre" vacio')
            RETURN
        END

        IF @Descripcion IS NULL
        BEGIN
            PRINT('campo "Descripcion" vacio')
            RETURN
        END

        IF @Precio <= 0 OR @Precio IS NULL
        BEGIN
            PRINT('campo "Precio" no valido')
            RETURN
        END

        IF @Stock < 0 OR @Stock IS NULL
        BEGIN
            PRINT('campo "Stock" no puede ser negativo')
            RETURN
        END

        IF @IDCategoria IS NULL
        BEGIN
            PRINT('campo "Categoria" sin definir')
            RETURN
        END


        IF  NOT EXISTS (
            SELECT 1
            FROM Producto
            WHERE Nombre = @Nombre
        )
        BEGIN
            INSERT INTO Producto (Nombre,Descripcion,Precio,Stock,IDCategoria) VALUES 
                                    (@Nombre,@Descripcion,@Precio,@Stock,@IDCategoria)
            print('nuevo producto añadido')
        END
        ELSE
        BEGIN

            UPDATE Producto
            set Stock = Stock + @Stock
            WHERE Nombre = @Nombre
            print('stock cargado')
        END
END

GO

-- Se encarga de verificar que los datos pasados al insert se carguen en relacion a cierta estructura.
CREATE TRIGGER cargarEmpleado on Empleados
INSTEAD OF INSERT
AS
BEGIN   
        DECLARE @NombreEmpleado VARCHAR(50) = ''
        DECLARE @DNI INTEGER = 0
        DECLARE @ROL VARCHAR(50) = ''
        DECLARE @IDRestaurante BIGINT = 0

        SELECT 
        @NombreEmpleado = Nombre,
        @DNI = DNI,
        @ROL = Rol,
        @IDRestaurante = IDRestaurante
        FROM inserted


        IF @NombreEmpleado IS NULL
        OR @NombreEmpleado LIKE '%[^a-zA-Z ]%'
        BEGIN
            PRINT('Nombre Incorrecto. (no debe incluir caracteres especiales y numeros)')
            RETURN
        END

        IF @DNI NOT BETWEEN 10000000 AND 99999999 OR @DNI IS NULL
        BEGIN
            PRINT('Debe contener 8 digitos')
            RETURN
        END

        IF @ROL NOT IN ('cajero', 'cocinero', 'gerente', 'manager') OR @ROL IS NULL
        BEGIN
        PRINT('Rol Incorrecto.')
        RETURN
        END

        IF @IDRestaurante IS NULL
        OR NOT EXISTS (
            SELECT 1
            FROM Restaurantes
            WHERE IDRestaurante = @IDRestaurante
        )
        BEGIN
            PRINT('Restaurante Incorrecto')
            RETURN
        END
        
        INSERT INTO Empleados (Nombre, DNI, Rol, IDRestaurante) VALUES
        (@NombreEmpleado,@DNI,@ROL,@IDRestaurante) 
        PRINT('Cargar Empleado Correcta')

END

GO

-- Se encarga de verificar la existencia de:
--- la venta pasado en el insert
--- El producto pasado en el insert
-- tambien se encarga de cargar el precio unitario en relacion al producto comprado.
CREATE TRIGGER verificarExistenciaDetalleVenta ON Detalla_venta
INSTEAD OF INSERT
AS
BEGIN
        DECLARE @IDVENTA BIGINT = 0
        DECLARE @IDPRODUCTO BIGINT = 0

        SELECT 
        @IDVENTA = IDVenta,
        @IDPRODUCTO = IDProducto
        FROM inserted

        IF NOT EXISTS (SELECT * FROM Venta WHERE IDVenta = @IDVENTA)
        BEGIN
            PRINT('Venta cargada no existe')
            RETURN
        END

        IF NOT EXISTS (SELECT * FROM Producto WHERE IDProducto = @IDPRODUCTO)
        BEGIN
            PRINT('Producto cargada no existe')
            RETURN
        END

        INSERT INTO Detalla_venta(cantidaVendida,IDVenta,IDProducto,tipoDePago,precioUnitario)
        SELECT ins.cantidaVendida,ins.IDVenta,ins.IDProducto,ins.tipoDePago,p.Precio
        FROM inserted ins
        JOIN producto p ON p.IDProducto = ins.IDProducto 
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

        INSERT INTO Venta(IDCliente, IDEmpleadoResponsable, IDRestaurante, Estado, modalidadConsumo)
        SELECT IDCliente, IDEmpleadoResponsable, IDRestaurante, Estado, modalidadConsumo
        FROM inserted

END


-- zona de test
-- Al menos 3 (tres) vistas. 
--(tipo_de_pago_transferencia, tipo_de_pago_efectivo, stock_de_productos)
-- Al menos 2 (dos) procedimientos almacenados, claramente diferenciados en su rol:
-- Uno de reporte parametrizado: recibe al menos un parámetro y
-- devuelve un conjunto de resultados (no una acción de escritura).
-- Uno de acción sobre la BD: modifica datos (inserta, actualiza o elimina)
-- como resultado de una operación de negocio.
-- (todos los buscar)
-- (modificarPedido)
-- Al menos 2 (dos) triggers, cubriendo:
-- Un evento de inserción (INSERT).
-- Un evento de eliminación (DELETE).
--(agregarProducto, bajaLogicaPoducto, agregarEmpleado)
