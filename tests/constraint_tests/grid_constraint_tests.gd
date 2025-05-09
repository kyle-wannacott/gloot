extends TestSuite

var inventory: Inventory
var item: InventoryItem
var grid_constraint: GridConstraint

const TEST_PROTOSET = preload("res://tests/data/protoset_grid.json")
const TEST_PROTOTYPE_ID = "item_2x2"


func init_suite():
    tests = [
        "test_set_size",
        "test_item_position",
        "test_item_size",
        "test_item_rect",
        "test_item_rotation",
        "test_add_item",
        "test_add_item_at",
        "test_create_and_add_item_at",
        "test_get_items_under",
        "test_move_item_to",
        "test_swap_items",
        "test_rect_free",
        "test_sort",
        "test_get_space_for",
        "test_serialize",
        "test_serialize_json",
    ]


func init_test() -> void:
    item = create_item(TEST_PROTOSET, TEST_PROTOTYPE_ID)
    inventory = create_inventory(TEST_PROTOSET)
    grid_constraint = enable_grid_constraint(inventory)


func cleanup_test() -> void:
    free_inventory(inventory)


func test_set_size() -> void:
    assert(grid_constraint.size == Vector2i(10, 10))

    grid_constraint.size = Vector2i(3, 3)
    assert(grid_constraint.size == Vector2i(3, 3))


func test_item_position() -> void:
    assert(grid_constraint.get_item_position(item) == Vector2i.ZERO)
    assert(inventory.add_item(item))

    var test_data := [
        {input = Vector2i(9, 9), expected = {return_value = false, position = Vector2i.ZERO}},
        {input = Vector2i(-1, -1), expected = {return_value = false, position = Vector2i.ZERO}},
        {input = Vector2i(8, 8), expected = {return_value = true, position = Vector2i(8, 8)}},
    ]

    for data in test_data:
        assert(grid_constraint.set_item_position(item, data.input) == data.expected.return_value)
        assert(grid_constraint.get_item_position(item) == data.expected.position)


func test_item_size() -> void:
    assert(grid_constraint.get_item_size(item) == Vector2i(2, 2))
    assert(inventory.add_item(item))

    var test_data := [
        {input = Vector2i(-1, -1), expected = {return_value = false, size = Vector2i(2, 2)}},
        {input = Vector2i(4, 4), expected = {return_value = true, size = Vector2i(4, 4)}},
        {input = Vector2i(15, 15), expected = {return_value = false, size = Vector2i(4, 4)}},
    ]

    for data in test_data:
        assert(grid_constraint.set_item_size(item, data.input) == data.expected.return_value)
        assert(grid_constraint.get_item_size(item) == data.expected.size)


func test_item_rect() -> void:
    assert(grid_constraint.get_item_rect(item) == Rect2i(0, 0, 2, 2))
    assert(inventory.add_item(item))

    var test_data := [
        {input = Rect2i(0, 0, -1, -1), expected = {return_value = false, rect = Rect2i(0, 0, 2, 2)}},
        {input = Rect2i(4, 4, 4, 4), expected = {return_value = true, rect = Rect2i(4, 4, 4, 4)}},
        {input = Rect2i(9, 9, 4, 4), expected = {return_value = false, rect = Rect2i(4, 4, 4, 4)}},
    ]

    for data in test_data:
        assert(grid_constraint.set_item_rect(item, data.input) == data.expected.return_value)
        assert(grid_constraint.get_item_rect(item) == data.expected.rect)


func test_item_rotation() -> void:
    const ITEM_SIZE := Vector2i(2, 1)
    const ROTATED_ITEM_SIZE := Vector2i(1, 2)
    inventory.add_item(item)
    assert(grid_constraint.set_item_size(item, ITEM_SIZE))
    assert(grid_constraint.get_item_rect(item) == Rect2i(Vector2i.ZERO, ITEM_SIZE))

    # Test default rotation
    assert(!GridConstraint.is_item_rotated(item))
    assert(!GridConstraint.is_item_rotation_positive(item))

    # Test set rotation
    grid_constraint.set_item_rotation(item, true)
    assert(GridConstraint.is_item_rotated(item))
    assert(grid_constraint.get_item_rect(item) == Rect2i(Vector2i.ZERO, ROTATED_ITEM_SIZE))

    # Test rotation
    assert(grid_constraint.rotate_item(item))
    assert(grid_constraint.get_item_rect(item) == Rect2i(Vector2i.ZERO, ITEM_SIZE))
    assert(grid_constraint.rotate_item(item))
    assert(grid_constraint.get_item_rect(item) == Rect2i(Vector2i.ZERO, ROTATED_ITEM_SIZE))

    # Test rotation direction
    GridConstraint.set_item_rotation_direction(item, true)
    assert(GridConstraint.is_item_rotation_positive(item))

    # Test obstructed rotation
    grid_constraint.set_item_rotation(item, false)
    assert(grid_constraint.get_item_rect(item) == Rect2i(Vector2i.ZERO, ITEM_SIZE))
    var new_item = grid_constraint.create_and_add_item_at(TEST_PROTOTYPE_ID, Vector2(0, 1))
    assert(new_item != null)
    assert(!grid_constraint.can_rotate_item(item))
    assert(!grid_constraint.set_item_rotation(item, true))
    assert(!grid_constraint.rotate_item(item))

    inventory.remove_item(new_item)


func test_add_item() -> void:
    grid_constraint.size = Vector2i(3, 3)
    assert(inventory.add_item(item))
    assert(grid_constraint.get_item_position(item) == Vector2i.ZERO)
    
    var item_1x1 = create_item(inventory.protoset, "item_1x1")
    grid_constraint.insertion_priority = GridConstraint.INSERTION_PRIORITY_VERTICAL
    assert(inventory.add_item(item_1x1))
    assert(grid_constraint.get_item_position(item_1x1) == Vector2i(0, 2))
    inventory.remove_item(item_1x1)

    grid_constraint.insertion_priority = GridConstraint.INSERTION_PRIORITY_HORIZONTAL
    assert(inventory.add_item(item_1x1))
    assert(grid_constraint.get_item_position(item_1x1) == Vector2i(2, 0))


func test_add_item_at() -> void:
    var test_data := [
        {input = Vector2i.ZERO, expected = {return_value = true, has_item = true, position = Vector2i.ZERO}},
        {input = Vector2i(4, 4), expected = {return_value = true, has_item = true, position = Vector2i(4, 4)}},
        {input = Vector2i(15, 15), expected = {return_value = false, has_item = false, position = Vector2i(4, 4)}},
    ]

    for data in test_data:
        assert(grid_constraint.add_item_at(item, data.input) == data.expected.return_value)
        assert(inventory.has_item(item) == data.expected.has_item)
        if data.expected.has_item:
            assert(grid_constraint.get_item_position(item) == data.expected.position)

        if inventory.has_item(item):
            inventory.remove_item(item)


func test_create_and_add_item_at() -> void:
    var test_data := [
        {input = Vector2i.ZERO, expected = {return_value = true, has_item = true, position = Vector2i.ZERO}},
        {input = Vector2i(4, 4), expected = {return_value = true, has_item = true, position = Vector2i(4, 4)}},
        {input = Vector2i(15, 15), expected = {return_value = false, has_item = false, position = Vector2i.ZERO}},
    ]

    for data in test_data:
        var new_item = grid_constraint.create_and_add_item_at(TEST_PROTOTYPE_ID, data.input)
        assert((new_item != null) == data.expected.return_value)
        assert(inventory.has_item(new_item) == data.expected.has_item)
        if (inventory.has_item(new_item)):
            assert(grid_constraint.get_item_position(new_item) == data.expected.position)

        if inventory.has_item(new_item):
            inventory.remove_item(new_item)


func test_get_items_under() -> void:
    var test_data := [
        {input = {item_positions = [Vector2i.ZERO], test_rect = Rect2i(0, 0, 1, 1)}, expected = 1},
        {input = {item_positions = [Vector2i.ZERO], test_rect = Rect2i(1, 1, 1, 1)}, expected = 1},
        {input = {item_positions = [Vector2i.ZERO], test_rect = Rect2i(2, 2, 1, 1)}, expected = 0},
        {input = {item_positions = [Vector2i.ZERO, Vector2i(2, 2)], test_rect = Rect2i(1, 1, 2, 2)}, expected = 2},
    ]

    for data in test_data:
        var new_items: Array[InventoryItem] = []
        for item_position in data.input.item_positions:
            var new_item := grid_constraint.create_and_add_item_at(TEST_PROTOTYPE_ID, item_position)
            assert(new_item != null)
            new_items.append(new_item)
        var items := grid_constraint.get_items_under(data.input.test_rect)
        assert(items.size() == data.expected)

        for new_item in new_items:
            inventory.remove_item(new_item)


func test_move_item_to() -> void:
    grid_constraint.add_item_at(item, Vector2i(2, 2))

    var test_data := [
        {input = Vector2i(1, 0), expected = true},
        {input = Vector2i(1, 1), expected = false},
        {input = Vector2i(4, 4), expected = true},
        {input = Vector2i(15, 15), expected = false},
    ]

    for data in test_data:
        var new_item = inventory.create_and_add_item(TEST_PROTOTYPE_ID)
        assert(new_item != null)
        assert(grid_constraint.move_item_to(new_item, data.input) == data.expected)
        assert((grid_constraint.get_item_position(new_item) == data.input) == data.expected)

        inventory.remove_item(new_item)


func test_swap_items() -> void:
    var new_item_1x1 = grid_constraint.create_and_add_item_at("item_1x1", Vector2i.ZERO)
    var new_item_2x2 = grid_constraint.create_and_add_item_at(TEST_PROTOTYPE_ID, Vector2i(1, 0))
    var new_item_2x2_2 = grid_constraint.create_and_add_item_at(TEST_PROTOTYPE_ID, Vector2i(0, 2))
    assert(new_item_1x1 != null)
    assert(new_item_2x2 != null)
    assert(new_item_2x2_2 != null)
    assert(!InventoryItem.swap(new_item_1x1, new_item_2x2))
    assert(InventoryItem.swap(new_item_2x2_2, new_item_2x2))
    assert(grid_constraint.get_item_position(new_item_2x2) == Vector2i(0, 2))
    assert(grid_constraint.get_item_position(new_item_2x2_2) == Vector2i(1, 0))


func test_rect_free() -> void:
    grid_constraint.add_item_at(item, Vector2i(2, 2))

    var test_data := [
        {input = {rect = Rect2i(-1, -1, 1, 1), exception = null}, expected = false},
        {input = {rect = Rect2i(0, 0, 1, 1), exception = null}, expected = true},
        {input = {rect = Rect2i(0, 0, 3, 3), exception = null}, expected = false},
        {input = {rect = Rect2i(0, 0, 3, 3), exception = item}, expected = true},
        {input = {rect = Rect2i(4, 4, 1, 1), exception = null}, expected = true},
        {input = {rect = Rect2i(4, 4, 15, 15), exception = null}, expected = false},
    ]
    
    for data in test_data:
        assert(grid_constraint.rect_free(data.input.rect, data.input.exception) == data.expected)


func test_sort() -> void:
    var item1 = grid_constraint.create_and_add_item_at("item_1x1", Vector2i.ZERO)
    var item2 = grid_constraint.create_and_add_item_at("item_1x1", Vector2i(1, 0))
    var item3 = grid_constraint.create_and_add_item_at("item_2x2", Vector2i(0, 1))

    grid_constraint.sort()
    assert(grid_constraint.get_item_position(item3) == Vector2i.ZERO)
    assert(grid_constraint.get_item_position(item1) == Vector2i(0, 2))
    assert(grid_constraint.get_item_position(item2) == Vector2i(0, 3))

    inventory.remove_item(item1)
    inventory.remove_item(item2)
    inventory.remove_item(item3)


func test_get_space_for() -> void:
    # Empty inventory
    var test_data := [
        {input = Vector2i.ONE, expected = 0},
        {input = Vector2i(2, 2), expected = 1},
        {input = Vector2i(3, 3), expected = 1},
        {input = Vector2i(4, 4), expected = 4},
    ]

    for data in test_data:
        grid_constraint.size = data.input
        assert(grid_constraint.get_space_for(item) == data.expected)

    # One item in inventory
    grid_constraint.size = Vector2i(2, 2)
    var item2 = inventory.create_and_add_item(TEST_PROTOTYPE_ID)
    test_data = [
        {input = Vector2i(2, 2), expected = 0},
        {input = Vector2i(3, 3), expected = 0},
        {input = Vector2i(4, 4), expected = 3},
    ]

    for data in test_data:
        grid_constraint.size = data.input
        assert(grid_constraint.get_space_for(item) == data.expected)

    inventory.remove_item(item2)


func test_serialize() -> void:
    grid_constraint.size = Vector2i(4, 2)
    grid_constraint.insertion_priority = GridConstraint.INSERTION_PRIORITY_HORIZONTAL
    var constraint_data = grid_constraint.serialize()
    var size = grid_constraint.size
    var insertion_priority = grid_constraint.insertion_priority

    grid_constraint.reset()
    assert(grid_constraint.size == GridConstraint.DEFAULT_SIZE)
    assert(grid_constraint.insertion_priority == GridConstraint.INSERTION_PRIORITY_VERTICAL)

    assert(grid_constraint.deserialize(constraint_data))
    assert(grid_constraint.size == size)
    assert(grid_constraint.insertion_priority == insertion_priority)
    

func test_serialize_json() -> void:
    grid_constraint.size = Vector2i(4, 2)
    grid_constraint.insertion_priority = GridConstraint.INSERTION_PRIORITY_HORIZONTAL
    var constraint_data = grid_constraint.serialize()
    var size = grid_constraint.size
    var insertion_priority = grid_constraint.insertion_priority

    # To and from JSON serialization
    var json_string: String = JSON.stringify(constraint_data)
    var test_json_conv: JSON = JSON.new()
    assert(test_json_conv.parse(json_string) == OK)
    constraint_data = test_json_conv.data

    grid_constraint.reset()
    assert(grid_constraint.size == GridConstraint.DEFAULT_SIZE)
    assert(grid_constraint.insertion_priority == GridConstraint.INSERTION_PRIORITY_VERTICAL)
    
    assert(grid_constraint.deserialize(constraint_data))
    assert(grid_constraint.size == size)
    assert(grid_constraint.insertion_priority == insertion_priority)
