```mermaid
sequenceDiagram
    participant Cliente
    participant Tienda
    participant Inventario
    participant Pago

    Cliente->>Tienda: realizarCompra()
    Cliente->>Tienda: seleccionarProducto()
    Cliente->>Tienda: enviarPedido()

    Tienda->>Inventario: verificarDisponibilidad()
    Inventario-->>Tienda: confirmarDisponibilidad(Sí/No)

    alt Producto disponible
        Tienda->>Cliente: mostrarPrecioTotal()
        Tienda->>Cliente: solicitarConfirmaciónPago()
        Cliente->>Pago: confirmarPago()
        Pago->>Tienda: procesarPago()
        Tienda->>Cliente: confirmarCompra()
    else Producto no disponible
        Tienda->>Cliente: mostrarMensaje("Producto agotado")
    end
