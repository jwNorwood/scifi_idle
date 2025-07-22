# Team Management Modal

This modal provides a drag-and-drop interface for managing your team composition and pet inventory.

## Features

- **Drag and Drop**: Click and drag pets between team slots and inventory
- **Team Slots**: Up to 6 pets can be in your active team
- **Pet Inventory**: Unlimited storage for pets not in your active team
- **Visual Feedback**: Slots highlight when hovering and during drag operations
- **Right-click to Remove**: Right-click on a pet to remove it from its current slot

## How to Use

1. **Opening the Modal**: Click the "Team" button in the Overworld header
2. **Moving Pets**:
   - Click and drag a pet from one slot to another
   - Drop pets from inventory to team slots to add them to your team
   - Drop pets from team slots to inventory to remove them from your team
3. **Reordering**: Drag pets within the same area to change their order
4. **Saving Changes**: Click "Save Changes" to apply your new team composition
5. **Canceling**: Click "Cancel" or "X" to discard changes

## Implementation Details

### Files Created:

- `Scenes/TeamManagment/TeamManagementModal.tscn` - Main modal scene
- `Scenes/TeamManagment/team_management_modal.gd` - Modal logic script
- `Scenes/TeamManagment/PetSlot.tscn` - Individual pet slot scene
- `Scenes/TeamManagment/pet_slot.gd` - Pet slot drag/drop functionality

### Integration:

- Added Team button to Overworld UI
- Connected to GlobalPlayer team data
- Emits events through EventBus when team changes
- Works with existing Pet resource system

## Technical Notes

- Uses Godot's built-in drag and drop system
- Supports both manual drag operations and Godot's `_get_drag_data`/`_drop_data` system
- Visual styles update dynamically during interactions
- Maintains data integrity with proper array management
- Integrates with existing event system for team updates

## Future Enhancements

- Add confirmation dialogs for destructive actions
- Implement pet stats display on hover
- Add team validation (e.g., minimum team size)
- Support for team presets/saved configurations
- Integration with combat system for team effectiveness metrics
