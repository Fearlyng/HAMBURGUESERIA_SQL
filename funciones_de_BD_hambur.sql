USE BD_HAMBURGUESERIA
GO
-- Buscar productos por nombre, combo.
CREATE PROCEDURE BUSCAR_PRODUCTO(@Nombre VARCHAR(20))
AS
BEGIN
    SELECT
    *
    FROM Producto
    WHERE Nombre = @Nombre
END

GO
-- Buscar Compra x Producto (NEW)
-- REVISAR (=)

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
-- ● Buscar cliente por nombre, por DNI, teléfono y producto pago.

CREATE PROCEDURE BUSCAR_CLIENTE_NOMBRE(@Nombre VARCHAR(50))
AS
BEGIN
    SELECT
    *
    FROM Clientes
    WHERE Nombre = @Nombre 
END
GO

CREATE PROCEDURE BUSCAR_CLIENTE_DNI(@DNI INTEGER)
AS
BEGIN
    SELECT
    *
    FROM Clientes
    WHERE DNI = @DNI 
END
GO

CREATE PROCEDURE BUSCAR_CLIENTE_TELEFONO(@Telefono INTEGER)
AS
BEGIN
    SELECT
    *
    FROM Clientes
    WHERE Telefono = @Telefono
END
GO

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

-- ● Consultar el estado de pedido: pedido, producción o entregado.
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


-- ● Consulta los productos con stock
CREATE VIEW stock_de_productos AS
    SELECT *
    FROM Producto P
    WHERE P.Stock > 0;

GO


-- ● Consultar los distintos horarios de atención y dirección de los restaurantes.
CREATE VIEW consultar_horarios_y_direccion AS
    SELECT 
    R.HorarioApertura,
    R.HorarioSalida,
    R.Direccion
    FROM Restaurantes R

-- ● Consultar si el pago fue hecho a través de transferencia o efectivo, y muestra quien lo  hizo
GO
CREATE VIEW tipo_de_pago_efectivo AS
SELECT
DV.IDTransaccion,
DV.tipoDePago
FROM Detalla_venta DV
WHERE tipoDePago = 'efectivo'

GO

CREATE VIEW tipo_de_pago_transferencia AS
SELECT
DV.IDTransaccion,
DV.tipoDePago
FROM Detalla_venta DV
WHERE tipoDePago = 'transferencia'
GO

-- ● Podrá realizar modificaciones y/o cancelar ventas (Manager).
--(procedimiento)
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


-- ● Podrá agregar o eliminar productos/combos al listado que ofrecen al público (baja logica).
GO
CREATE TRIGGER bajaLogicaPoducto on Producto
INSTEAD OF DELETE
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
            DECLARE @ID BIGINT = 0

            SELECT @ID = IDProducto
            FROM deleted

            UPDATE Producto
            SET Stock = 0
            WHERE IDProducto = @ID
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
    END CATCH
END

GO
--(Nombre,Descripcion,Precio,Stock,IDCategoria)
-- nombre y IDCategoria no puden ser nulus
-- precio y stock >= 0
CREATE TRIGGER cargarProducto on Producto
INSTEAD OF INSERT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
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
        END

        IF @Descripcion IS NULL
        BEGIN
            PRINT('campo "Descripcion" vacio')
        END

        IF @Precio <= 0 OR @Precio IS NULL
        BEGIN
            PRINT('campo "Precio" no valido')
        END

        IF @Stock < 0 OR @Stock IS NULL
        BEGIN
            PRINT('campo "Stock" no puede ser negativo')
        END

        IF @IDCategoria IS NULL
        BEGIN
            PRINT('campo "Categoria" sin definir')
        END


        IF  NOT EXISTS (
            SELECT 1
            FROM Producto
            WHERE Nombre = @Nombre
        )
        BEGIN

            IF @Nombre IS NOT NULL
            AND @Descripcion IS NOT NULL 
            AND @Stock >= 0 AND @Stock IS NOT NULL 
            AND @Precio > 0  AND @Precio IS NOT NULL 
            AND @IDCategoria IS NOT NULL
            BEGIN
                INSERT INTO Producto (Nombre,Descripcion,Precio,Stock,IDCategoria) VALUES 
                                    (@Nombre,@Descripcion,@Precio,@Stock,@IDCategoria)

                print('cargado')
            END
            ELSE
            BEGIN
                PRINT('no cargado')
            END

        END
        ELSE
        BEGIN

        UPDATE Producto
        set Stock = Stock + @Stock
        WHERE Nombre = @Nombre

        END


        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
    END CATCH
END



-- ● Podrá agregar o eliminar empleados/clientes del sistema. (-[ NO LO SE ]-)

GO
--(Nombre char(50), DNI INT, Rol char(50), IDRestaurante BIGINT)
-- Nombre sin numeros
-- DNI sin letras ni caracteres, 8 digitos
-- Rol = cajero, cocinero, gerente o manager
-- IDRestaurante existe
CREATE TRIGGER cargarEmpleado on Empleados
INSTEAD OF INSERT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
        
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
        END
        ELSE
        BEGIN
        PRINT('Nombre correcto')
        END

        IF @DNI NOT BETWEEN 10000000 AND 99999999 OR @DNI IS NULL
        BEGIN
            PRINT('Debe contener 8 digitos')
        END
        ELSE
        BEGIN
        PRINT('DNI Cargado Correctamente')
        END

        IF @ROL NOT IN ('cajero', 'cocinero', 'gerente', 'manager') OR @ROL IS NULL
        BEGIN
        PRINT('Rol Incorrecto.')
        END
        ELSE
        BEGIN
        PRINT('Rol Correcto')
        END

        IF @IDRestaurante IS NULL
        OR NOT EXISTS (
            SELECT 1
            FROM Restaurantes
            WHERE IDRestaurante = @IDRestaurante
        )
        BEGIN
        PRINT('Restaurante Incorrecto')
        END
        ELSE
        BEGIN
        PRINT('Restaurante Correcto')
        END

        IF @IDRestaurante IS NOT NULL
        AND EXISTS (
            SELECT 1
            FROM Restaurantes
            WHERE IDRestaurante = @IDRestaurante
        )
        AND @ROL IN ('cajero', 'cocinero', 'gerente', 'manager') AND @ROL IS NOT NULL
        AND @DNI BETWEEN 10000000 AND 99999999 AND @DNI IS NOT NULL
        AND @NombreEmpleado NOT LIKE '%[^a-zA-Z ]%' AND @NombreEmpleado IS NOT NULL
        BEGIN
        INSERT INTO Empleados (Nombre, DNI, Rol, IDRestaurante) VALUES
        (@NombreEmpleado,@DNI,@ROL,@IDRestaurante) 
        PRINT('entro')
        END
        ELSE
        BEGIN
        PRINT('no entro')
        END

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
    END CATCH
END

--DROP TRIGGER cargarEmpleado

GO

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

--DROP TRIGGER verificarExistenciaDetalleVenta

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
