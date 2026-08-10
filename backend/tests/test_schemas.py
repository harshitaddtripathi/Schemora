from app.schemas.common import APIResponse, ErrorDetail, ErrorResponse, PaginationMeta


def test_api_response_success_defaults():
    response = APIResponse(data={"key": "value"})
    assert response.success is True
    assert response.message == "Operation completed successfully"
    assert response.data == {"key": "value"}
    assert response.errors is None
    assert response.timestamp is not None


def test_error_response_structure():
    err_detail = ErrorDetail(code="INVALID_INPUT", message="Field missing", field="annual_income")
    err_response = ErrorResponse(message="Validation failed", errors=[err_detail])
    assert err_response.success is False
    assert err_response.message == "Validation failed"
    assert len(err_response.errors) == 1
    assert err_response.errors[0].code == "INVALID_INPUT"
    assert err_response.errors[0].field == "annual_income"


def test_pagination_meta():
    meta = PaginationMeta(
        page=1,
        page_size=10,
        total_items=25,
        total_pages=3,
        has_next=True,
        has_prev=False,
    )
    assert meta.page == 1
    assert meta.total_pages == 3
    assert meta.has_next is True
    assert meta.has_prev is False
